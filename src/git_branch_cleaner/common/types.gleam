import gleam/option.{type Option}

pub type Branch {
  Branch(name: String)
}

pub type BranchSlice {
  BranchSlice(branch: Branch, commits: List(Commit))
}

pub type BranchDiff {
  BranchDiff(base: BranchSlice, target: BranchSlice)
}

pub type BranchType {
  Local
  Remote
}

pub type Commit {
  Commit(hash: String, summary: String, description: Option(String))
}

pub type GitRunner =
  fn(List(String)) -> Result(String, ShellError)

pub type GitError {
  GitCommandError(error: ShellError)
  GitParsingError(content: String, parse_type: GitParseType)
}

pub type GitParseType {
  CommitLog
  BranchLog
}

pub type ShellError =
  #(Int, String)

pub type GitBranchCleanerConfig {
  GitBranchCleanerConfig(
    branch_max_depth: Int,
    ref_branch_name: String,
    ref_branch_type: BranchType,
    merge_strategy: MergeStrategy,
    branch_merge_matchers: List(BranchMergeMatcher),
  )
}

pub type MergeStrategy {
  CreateMergeCommit
  SquashAndMerge
  RebaseAndMerge
}

pub type BranchMergeMatcher {
  DefaultMergeMessage
  BranchNamePrefix
  SquashedCommitsMessage
}

pub type CommandError {
  FindError(GitError)
  RemoveError(CleanupBranchesError)
}

pub type CleanupBranchesError {
  BranchesNotFound(branches: List(Branch))
  BranchesNotRemoved(branches: List(Branch))
  RemoveGitError(error: GitError)
}

pub type CliCommand {
  Find(max_depth: Option(Int), ref_branch: Option(String))
  Remove(max_depth: Option(Int), ref_branch: Option(String))
  Help
}

pub type CliCommandError {
  UnknownCommand(command: String)
  UnknownOption(option: String)
  MissingOptionValue(option: String)
  IncorrectOptionValue(option: String, value: String)
}
