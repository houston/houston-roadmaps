class Houston::Roadmaps::RoadmapCommitPresenter

  def initialize(commits)
    @commits = commits
  end

  def as_json(*args)
    @commits.map(&method(:to_hash))
  end

  def to_hash(commit)
    { id: commit.id,
      createdAt: commit.created_at,
      user: commit.user && {
        email: commit.user.email,
        name: commit.user.name },
      message: commit.message,
      diffs: commit.diffs.map { |diff|
        x = {
          milestoneId: diff["milestone_id"],
          status: diff["status"]
        }
        x["attributes"] = diff["attributes"].each_with_object({}) { |(key, value), new_hash|
          key = ActiveSupport::Inflector.camelize(key, false)
          key = "removed" if key == "deleted"
          new_hash[key] = value
        } if diff.key?("attributes")
        x
    } }
  end

end
