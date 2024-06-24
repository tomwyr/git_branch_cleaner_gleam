import git_branch_cleaner/finder
import git_branch_cleaner/types.{
  type BranchCleanerConfig, Branch, BranchCleanerConfig,
}
import gleam/list
import gleam/string
import gleeunit/should

pub fn passes_branch_max_depth_to_git_commands_test() {
  test_branch_cleaner_config(
    of: BranchCleanerConfig(..finder.get_default_config(), branch_max_depth: 7),
    using: fn(args_str) {
      case args_str {
        "branch" -> ["  master", "  feature"]
        "branch -r" -> []
        "log --format=\"%h %s%n%w(0,2,2)%b\" master -n 7" -> [
          "ba25f3ac2 Commit 2", "fdd67acf1 Commit 1",
        ]
        "log --format=\"%h %s%n%w(0,2,2)%b\" feature -n 7" -> [
          "2f987f22f Commit 2", "fdd67acf1 Commit 1",
        ]
        "log --format=\"%h %s%n%w(0,2,2)%b\" master..feature" -> [
          "ba25f3ac2 Commit 2",
        ]
        "log --format=\"%h %s%n%w(0,2,2)%b\" feature..master" -> [
          "2f987f22f Commit 2",
        ]
        _ -> panic
      }
    },
    expect: ["feature"],
  )
}

pub fn passes_ref_branch_name_to_git_commands_test() {
  test_branch_cleaner_config(
    of: BranchCleanerConfig(
      ..finder.get_default_config(),
      ref_branch_name: "main",
    ),
    using: fn(args_str) {
      case args_str {
        "branch" -> ["  main", "  feature"]
        "branch -r" -> []
        "log --format=\"%h %s%n%w(0,2,2)%b\" main -n 7" -> [
          "ba25f3ac2 Commit 2", "fdd67acf1 Commit 1",
        ]
        "log --format=\"%h %s%n%w(0,2,2)%b\" feature -n 7" -> [
          "2f987f22f Commit 2", "fdd67acf1 Commit 1",
        ]
        "log --format=\"%h %s%n%w(0,2,2)%b\" main..feature" -> [
          "ba25f3ac2 Commit 2",
        ]
        "log --format=\"%h %s%n%w(0,2,2)%b\" feature..main" -> [
          "2f987f22f Commit 2",
        ]
        _ -> panic
      }
    },
    expect: ["feature"],
  )
}

fn test_branch_cleaner_config(
  of config: BranchCleanerConfig,
  using answer: fn(String) -> List(String),
  expect branches: List(String),
) {
  let git_runner = fn(args) {
    let args_str = string.join(args, " ")
    Ok(answer(args_str) |> string.join("\n"))
  }

  finder.find_branches_to_cleanup(matching: config, using: git_runner)
  |> should.be_ok()
  |> should.equal(branches |> list.map(Branch))
}
