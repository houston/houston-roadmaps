require "progressbar"

class AddDiffsToRoadmapCommits < ActiveRecord::Migration[5.0]
  def up
    add_column :roadmap_commits, :diffs, :jsonb


    # 1. Delete the commits for deleted roadmaps
    RoadmapCommit.where("roadmap_id NOT IN (?)", Roadmap.select(:id)).delete_all


    pbar = ProgressBar.new("commits", RoadmapCommit.count)
    Roadmap.all.each do |roadmap|


      # 2. Delete the commits that don't actually make any changes to a roadmap
      commits = roadmap.commits.preload(milestone_versions: :versioned).reorder(created_at: :desc).to_a
      commits.each do |commit|
        next if commit.milestone_versions.any?
        puts "\e[90mDeleting commit #{commit.id} \e[0m#{commit.message}\e[0;90m for roadmap #{roadmap.id} \e[0m#{roadmap.name}\e[0;90m: it has no versions\e[0m"
        commit.destroy
      end
      commits = commits.reject(&:destroyed?)
      next if commits.none?


      # 3. What's the current state of each Roadmap?
      #    (Our commits should lead up to this.)
      milestones = RoadmapMilestone.including_destroyed
        .preload(:milestone)
        .where(roadmap_id: roadmap.id)
        .to_a
      state = milestones.each_with_object({}) do |milestone, state|
        state[milestone.id] = {
          milestone_id: milestone.milestone_id,
          deleted: milestone.destroyed_at.present?,

          name: milestone.milestone.name,
          band: milestone.band,
          lanes: milestone.lanes,
          start_date: milestone.start_date,
          end_date: milestone.end_date }
      end


      # 4. What's the whole state of each milestone after each commit?
      state_after_commit = {}
      commits.each do |commit|
        state_after_commit[commit.id] = state.deep_dup

        # Now "undo" the commit from the state
        commit.milestone_versions.each do |version|
          milestone_id = version.versioned_id

          if version.number == 1
            state.delete milestone_id
          else
            version.modifications.each do |attribute, (before, after)|
              attribute = attribute.to_sym

              if attribute == :destroyed_at
                attribute = :deleted
                before = before.present?
                after = after.present?
              end

              unless state.key?(milestone_id)
                puts "\e[31mno state in roadmap #{roadmap.id} for RoadmapMilestone with id #{milestone_id}\e[0m"
                exit 1
              end

              unless state.fetch(milestone_id).key?(attribute)
                puts "\e[31mstate for RoadmapMilestone with id #{milestone_id} has no value for #{attribute.inspect}\e[0m"
                exit 1
              end

              if state.fetch(milestone_id).fetch(attribute) == before
                puts "\e[31mbefore value for #{attribute} of RoadmapMilestone with id #{milestone_id} (#{before.inspect} : #{before.class}) is already the state of this milestone; skipping this change\e[0m"
                next
              end

              unless state.fetch(milestone_id).fetch(attribute) == after
                puts "\e[31mafter value for #{attribute} of RoadmapMilestone with id #{milestone_id} (#{after.inspect} : #{after.class}) doesn't match state (#{state[milestone_id][attribute].inspect} : #{state[milestone_id][attribute].class}); skipping this change\e[0m"
                exit 1
              end

              state[milestone_id][attribute] = before
            end
          end
        end
      end


      # 5. Scrape out milestones that were deleted before we started
      #    versioning Roadmaps.
      commits = commits.reverse
      initial_commit = commits.shift
      initial_state = state_after_commit.fetch(initial_commit.id)
      originally_deleted = initial_state.select { |_, attributes| attributes[:deleted] }.keys
      state_after_commit.each { |_, state| state.except! *originally_deleted }


      # 6. Play the states forward and reduce them to diffs
      initial_commit.update_column(:diffs, initial_state.map do |_, attributes|
        { milestone_id: attributes.fetch(:milestone_id),
          status: "added",
          attributes: attributes.except(:deleted, :milestone_id) }
      end)

      prev_state = initial_state
      commits.each do |commit|
        state = state_after_commit.fetch(commit.id)
        diffs = state.each_with_object([]) do |(milestone_id, attributes), diffs|
          status = "modified"
          if prev_state.key?(milestone_id)
            prev_attributes = prev_state[milestone_id]
            next if prev_attributes == attributes
            status = "added" if prev_attributes[:deleted] && !attributes[:deleted]
            status = "deleted" if !prev_attributes[:deleted] && attributes[:deleted]
          else
            status = "added"
          end

          diff = { milestone_id: attributes[:milestone_id], status: status }
          diff[:attributes] = attributes.except(:deleted, :milestone_id) if status == "added"
          diff[:attributes] = differences_between(attributes, prev_state[milestone_id]) if status == "modified"
          diffs.push diff
        end

        if diffs.empty?
          puts "\e[31mCommit #{commit.id} \e[1m#{commit.message}\e[0;31m for roadmap #{roadmap.id} \e[1m#{roadmap.name}\e[0;31m: has no diffs\e[0m"
        end

        commit.update_column :diffs, diffs
        prev_state = state
        pbar.inc
      end
    end


    # 7. Double-check for commits with empty diffs
    empty_commits = RoadmapCommit.where("diffs = '[]'::jsonb").count
    if empty_commits > 0
      puts "\e[31mEmpty commits: \e[1m#{empty_commits}\e[0m"
      exit 1
    end

    change_column_null :roadmap_commits, :diffs, false
  end


  def down
    remove_column :roadmap_commits, :diffs
  end

private

  def differences_between(attributes, prev_attributes)
    attributes.select { |attribute, new_value| new_value != prev_attributes[attribute] }
  end

end
