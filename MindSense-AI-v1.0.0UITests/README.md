# MindSense UI Snapshot Tests

These UI tests verify:

- `Today`
- `Regulate`
- `Data`
- `Settings` (opened from profile/access menu)
- deterministic `Today -> Regulate` CTA routing with timer -> complete -> post-session check-in
- `Data` 7-day experiment lifecycle (`start -> active -> complete -> result saved`)
- snapshot matrix across `light` and `dark` appearance
- dynamic type scaling at accessibility sizes (`AXXXL`)
- interaction latency budgets for tab transitions and primary completion flows

The tests launch with:

- `-uitest-reset`
- `-uitest-ready`
- `-uitest-system | -uitest-light | -uitest-dark`
- `-uitest-enable-haptics 0|1`
- `-uitest-reduce-motion 0|1`

so the app starts in a deterministic post-onboarding state.

For dynamic type tests, `UIPreferredContentSizeCategoryName` is passed through launch environment.
