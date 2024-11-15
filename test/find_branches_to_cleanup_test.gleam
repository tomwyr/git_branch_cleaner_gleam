import git_branch_cleaner/common/types.{
  type Branch, type GitBranchCleanerConfig, type GitRunner, Branch,
  BranchNamePrefix, DefaultMergeMessage, GitBranchCleanerConfig,
}
import git_branch_cleaner/core/config
import git_branch_cleaner/core/finder
import git_runner.{run_test_git}
import gleam/list
import gleeunit/should

pub fn finds_no_branches_for_single_branch_repo_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master"],
      remote_branches: [],
      log_limited: fn(_) {
        ["d34cd1061 Commit 3", "48ae1312c Commit 2", "e3bd998e5 Commit 1"]
      },
      log_diff: ignore_log_diff,
    ),
    expect: [],
  )
}

pub fn finds_no_branches_for_branch_not_merged_into_ref_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> ["77776f5ae Commit 3", "2a6ceec75 Commit 1"]
          "feature" -> ["c2c8e45f8 Commit 2", "2a6ceec75 Commit 1"]
          _ -> panic
        }
      },
      log_diff: ignore_log_diff,
    ),
    expect: [],
  )
}

pub fn finds_branch_merged_into_ref_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> ["d40d5be9a Commit 2", "629733525 Commit 1"]
          "feature" -> ["1d88768b9 Commit 2", "629733525 Commit 1"]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature", "master" -> ["d40d5be9a Commit 2"]
          "master", "feature" -> ["1d88768b9 Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: ["feature"],
  )
}

pub fn finds_no_branches_for_branch_deeper_than_max_depth_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> [
            "a41c271a8 Branch 6", "65f548de8 Commit 5", "dbf317d96 Commit 4",
            "0df5deb72 Commit 3", "bda3be7ec Commit 2",
          ]
          "feature" -> ["3755b6927 Commit 2", "3388165af Commit 1"]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature", "master" -> [
            "a41c271a8 Branch 6", "65f548de8 Commit 5", "dbf317d96 Commit 4",
            "0df5deb72 Commit 3", "bda3be7ec Commit 2",
          ]
          "master", "feature" -> ["3755b6927 Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: [],
  )
}

pub fn finds_branch_for_branch_with_depth_equal_to_max_depth_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> [
            "4c3357a0b Commit 5", "59bd688d0 Commit 4", "c4e7b5162 Commit 3",
            "ef3403930 Commit 2", "f30f87754 Commit 1",
          ]
          "feature" -> ["bda3be7ec Commit 2", "f30f87754 Commit 1"]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature", "master" -> [
            "4c3357a0b Commit 5", "59bd688d0 Commit 4", "c4e7b5162 Commit 3",
            "ef3403930 Commit 2",
          ]
          "master", "feature" -> ["bda3be7ec Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: ["feature"],
  )
}

pub fn finds_branch_with_multiple_commits_merged_into_ref_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> [
            "6708db115 Commit 4\n  * Commit 3\n\n  * Commit 2",
            "3643c1bc4 Commit 1",
          ]
          "feature" -> [
            "41d41abf0 Commit 3", "be424315f Commit 2", "3643c1bc4 Commit 1",
          ]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature", "master" -> [
            "6708db115 Commit 4\n  * Commit 3\n\n  * Commit 2",
          ]
          "master", "feature" -> ["41d41abf0 Commit 3", "be424315f Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: ["feature"],
  )
}

pub fn finds_no_branches_for_branch_merged_but_not_deleted_from_remote_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature"],
      remote_branches: ["origin/feature"],
      log_limited: fn(branch) {
        case branch {
          "master" -> [
            "dc7c13e21 Commit 4\n  * Commit 3\n\n  * Commit 2",
            "2a52f0971 Commit 1",
          ]
          "feature" -> [
            "0d51efa2a Commit 3", "5c7700098 Commit 2", "2a52f0971 Commit 1",
          ]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature", "master" -> [
            "dc7c13e21 Commit 4\n  * Commit 3\n\n  * Commit 2",
          ]
          "master", "feature" -> ["0d51efa2a Commit 3", "5c7700098 Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: [],
  )
}

pub fn finds_multiple_branches_with_multiple_commits_merged_into_ref_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature-a", "feature-b"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> [
            "3fe43fbf7 Commit 4\n  * Commit 3\n\n  * Commit 2",
            "86d6dac4f Commit 7\n  * Commit 6\n\n  * Commit 5",
            "cfa717aed Commit 1",
          ]
          "feature-a" -> [
            "01ae1f5cf Commit 3", "e1d50ee17 Commit 2", "cfa717aed Commit 1",
          ]
          "feature-b" -> [
            "3951ac595 Commit 6", "88c8a31b9 Commit 5", "cfa717aed Commit 1",
          ]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature-a", "master" -> [
            "3fe43fbf7 Commit 4\n  * Commit 3\n\n  * Commit 2",
          ]
          "master", "feature-a" -> ["01ae1f5cf Commit 3", "e1d50ee17 Commit 2"]
          "feature-b", "master" -> [
            "3fe43fbf7 Commit 4\n  * Commit 3\n\n  * Commit 2",
            "86d6dac4f Commit 7\n  * Commit 6\n\n  * Commit 5",
          ]
          "master", "feature-b" -> ["3951ac595 Commit 6", "88c8a31b9 Commit 5"]
          _, _ -> panic
        }
      },
    ),
    expect: ["feature-a", "feature-b"],
  )
}

pub fn finds_multiple_branches_with_single_commits_merged_into_ref_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature-a", "feature-b"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> [
            "910ca29d7 Commit 3", "ca7d64d26 Commit 2", "e403d84ec Commit 1",
          ]
          "feature-a" -> ["066c13611 Commit 2", "e403d84ec Commit 1"]
          "feature-b" -> ["ece47178d Commit 3", "e403d84ec Commit 1"]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature-a", "master" -> ["910ca29d7 Commit 3", "ca7d64d26 Commit 2"]
          "master", "feature-a" -> ["066c13611 Commit 2"]
          "feature-b", "master" -> ["910ca29d7 Commit 3", "ca7d64d26 Commit 2"]
          "master", "feature-b" -> ["ece47178d Commit 3"]
          _, _ -> panic
        }
      },
    ),
    expect: ["feature-a", "feature-b"],
  )
}

pub fn finds_multiple_branches_with_common_history_above_ref_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature-a", "feature-b"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> [
            "160d15aa3 Commit 6\n  * Commit 4\n\n  * Commit 2",
            "7fd4542bb Commit 5\n  * Commit 3\n\n  * Commit 2",
            "9fa19cd74 Commit 1",
          ]
          "feature-a" -> [
            "04746a6c1 Commit 3", "d5a476811 Commit 2", "9fa19cd74 Commit 1",
          ]
          "feature-b" -> [
            "024d30b45 Commit 4", "d5a476811 Commit 2", "9fa19cd74 Commit 1",
          ]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature-a", "master" -> [
            "160d15aa3 Commit 6\n  * Commit 4\n\n  * Commit 2",
            "7fd4542bb Commit 5\n  * Commit 3\n\n  * Commit 2",
          ]
          "master", "feature-a" -> ["04746a6c1 Commit 3", "d5a476811 Commit 2"]
          "feature-b", "master" -> [
            "160d15aa3 Commit 6\n  * Commit 4\n\n  * Commit 2",
            "7fd4542bb Commit 5\n  * Commit 3\n\n  * Commit 2",
          ]
          "master", "feature-b" -> ["024d30b45 Commit 4", "d5a476811 Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: ["feature-a", "feature-b"],
  )
}

pub fn finds_multiple_branches_stacked_on_top_of_each_other_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature-a", "feature-b"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> [
            "081513206 Commit 4\n  * Commit 3\n\n  * Commit 2",
            "371fc576a Commit 2", "51b724442 Commit 1",
          ]
          "feature-a" -> ["a6afff21a Commit 2", "51b724442 Commit 1"]
          "feature-b" -> [
            "530d7b15c Commit 3", "a6afff21a Commit 2", "51b724442 Commit 1",
          ]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature-a", "master" -> [
            "081513206 Commit 4\n  * Commit 3\n\n  * Commit 2",
            "371fc576a Commit 2",
          ]
          "master", "feature-a" -> ["a6afff21a Commit 2"]
          "feature-b", "master" -> [
            "081513206 Commit 4\n  * Commit 3\n\n  * Commit 2",
            "371fc576a Commit 2",
          ]
          "master", "feature-b" -> ["530d7b15c Commit 3", "a6afff21a Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: ["feature-a", "feature-b"],
  )
}

pub fn finds_branches_merged_with_branch_name_in_commit_message_test() {
  test_find_branches_to_cleanup(
    using: run_test_git(
      local_branches: ["master", "feature"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> ["8fed06b5f Merge branch 'feature'", "329d837a4 Commit 1"]
          "feature" -> ["03975432e Commit 2", "329d837a4 Commit 1"]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature", "master" -> ["8fed06b5f Merge branch 'feature'"]
          "master", "feature" -> ["03975432e Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: ["feature"],
  )
}

pub fn finds_branch_used_as_prefix_when_prefix_matcher_is_in_config_test() {
  test_find_branches_to_cleanup_with_config(
    config: GitBranchCleanerConfig(
      ..config.default(),
      branch_merge_matchers: [BranchNamePrefix],
    ),
    using: run_test_git(
      local_branches: ["master", "feature-1"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> [
            "571bd3f44 feature-1 Merge Commit 2", "93baf4f74 Commit 1",
          ]
          "feature-1" -> ["e51a0c5de Commit 2", "93baf4f74 Commit 1"]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature-1", "master" -> ["571bd3f44 feature-1 Merge Commit 2"]
          "master", "feature-1" -> ["e51a0c5de Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: ["feature-1"],
  )
}

pub fn finds_branch_when_only_last_path_segment_matches_prefix_test() {
  test_find_branches_to_cleanup_with_config(
    config: GitBranchCleanerConfig(
      ..config.default(),
      branch_merge_matchers: [BranchNamePrefix],
    ),
    using: run_test_git(
      local_branches: ["master", "feature/id-123"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> ["b1b9a43ea id-123 Merge Commit 2", "57c52f497 Commit 1"]
          "feature/id-123" -> ["e97b65545 Commit 2", "57c52f497 Commit 1"]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature/id-123", "master" -> ["b1b9a43ea id-123 Merge Commit 2"]
          "master", "feature/id-123" -> ["e97b65545 Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: ["feature/id-123"],
  )
}

pub fn finds_no_branch_used_as_prefix_when_prefix_matcher_is_not_in_config_test() {
  test_find_branches_to_cleanup_with_config(
    config: GitBranchCleanerConfig(
      ..config.default(),
      branch_merge_matchers: [DefaultMergeMessage],
    ),
    using: run_test_git(
      local_branches: ["master", "feature-1"],
      remote_branches: [],
      log_limited: fn(branch) {
        case branch {
          "master" -> [
            "90ff9de1f feature-1 Merge Commit 2", "e9c51f22b Commit 1",
          ]
          "feature-1" -> ["3b19f169a Commit 2", "e9c51f22b Commit 1"]
          _ -> panic
        }
      },
      log_diff: fn(base, target) {
        case base, target {
          "feature-1", "master" -> ["90ff9de1f feature-1 Merge Commit 2"]
          "master", "feature-1" -> ["3b19f169a Commit 2"]
          _, _ -> panic
        }
      },
    ),
    expect: [],
  )
}

fn test_find_branches_to_cleanup(
  using git_runner: GitRunner,
  expect branches: List(String),
) {
  test_find_branches_to_cleanup_with_config(
    config: config.default(),
    using: git_runner,
    expect: branches,
  )
}

fn test_find_branches_to_cleanup_with_config(
  config config: GitBranchCleanerConfig,
  using git_runner: GitRunner,
  expect branches: List(String),
) {
  finder.find_branches_to_cleanup(for: config, using: git_runner)
  |> should.be_ok()
  |> should.equal(branches |> list.map(Branch))
}

fn ignore_log_diff(_: String, _: String) {
  []
}
