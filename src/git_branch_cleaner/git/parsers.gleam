import git_branch_cleaner/common/types.{
  type Branch, type BranchType, type Commit, type GitError, Branch, BranchLog,
  Commit, CommitLog, GitParsingError, Local, Remote,
}
import gleam/list
import gleam/option.{None, Some}
import gleam/regex.{type Match, Match}
import gleam/result
import gleam/string

pub fn parse_branch_log(
  branch_log: String,
  branch_type: BranchType,
) -> List(Result(Branch, GitError)) {
  branch_log
  |> string.split("\n")
  |> list.map(parse_branch_line(_, with: branch_type))
}

pub fn parse_commits_log(commits_log: String) -> Result(List(Commit), GitError) {
  case commits_log {
    "" -> Ok([])
    _ -> {
      let assert Ok(commit_regex) =
        regex.from_string("(\\w+) (.+)((?:\n+  .+)+)?")
      let matches = regex.scan(with: commit_regex, content: commits_log)

      matches
      |> list.map(parse_commit_match)
      |> result.all()
    }
  }
}

fn parse_branch_line(branch_line: String, with branch_type: BranchType) {
  let assert Ok(branch_regex) =
    regex.from_string(case branch_type {
      Local -> "^(?:\\*| ) (.+)$"
      Remote -> "^  (?:.+?\\/)(.+)$"
    })
  let matches = regex.scan(with: branch_regex, content: branch_line)

  case matches {
    [Match(_, [Some(branch_name)])] -> Ok(Branch(name: branch_name))
    _ -> Error(GitParsingError(content: branch_line, parse_type: BranchLog))
  }
}

fn parse_commit_match(commit_match: Match) {
  case commit_match {
    Match(_, [Some(commit_hash), Some(commit_summary), ..rest]) -> {
      let description = case rest {
        // Remove leading line break catched by each description group.
        [Some("\n" <> description)] -> Some(description)
        _ -> None
      }
      Ok(Commit(
        hash: commit_hash,
        summary: commit_summary,
        description: description,
      ))
    }
    _ ->
      Error(GitParsingError(
        content: commit_match.content,
        parse_type: CommitLog,
      ))
  }
}
