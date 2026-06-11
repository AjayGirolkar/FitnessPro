# FitnessPro — Roadmap / Deferred Work

Built so far (session 1): XcodeGen project, dark design system, mock auth, landing,
**full HERO flow** (onboarding questionnaire + Quick Start → AI/local plan generation
→ result), root coordinator + AppState, workout library (browse/search/detail with
streamed images), Home dashboard, Plan tab, Profile + AI-key settings, unit tests.

Next sessions, roughly in priority order.

## 1. Workout Player ✅ DONE (session 2)
- Full-screen runner from a `PlanDay`: set tracker, rep/weight steppers, timed-move countdown.
- Rest timer w/ countdown ring, +15s / skip, haptic + sound cue on rest end, auto-advance.
- "Complete workout" → `CompletedWorkout` logged to `AppState.completions` + day streak on Home.
- Files: `Features/WorkoutPlayer/{Model,ViewModel,View}`, factory in `AppContainer`,
  launched from Home "Start today's workout" + any `PlanDayCard` (Home/Plan tabs).
- Tests: `WorkoutPlayerViewModelTests` (flow/finish/volume). 25 tests green.
- For #3: completions persisted but only surfaced as a streak — no charts/history yet.

## 2. Real authentication (replace MockAuthService)
- Firebase Auth + GoogleSignIn-iOS + Sign in with Apple, behind existing `AuthService`.
- Needs: Firebase project, `GoogleService-Info.plist`, URL scheme, SPM deps in `project.yml`.
- Move session token to **Keychain** (`Core/Storage/KeychainStore`), not UserDefaults.

## 3. Progress tracking ✅ DONE (session 3)
- New **Progress tab** (`MainTabView`): lifetime stat grid (workouts/streak/volume/minutes),
  weekly-activity bar chart (volume/sessions/minutes toggle), per-session volume trend
  (line+area), personal records. Swift Charts, no deps.
- Files: `Features/Progress/{Model/ProgressMetrics,ViewModel/ProgressViewModel,View/ProgressView}`.
  `ProgressMetrics` is pure (testable) aggregation over `AppState.completions`.
  View type is `ProgressDashboardView` (avoid clash w/ SwiftUI `ProgressView`).
- Factory `makeProgressViewModel()` in `AppContainer`.
- TODO: weight-log entry UI; unit tests for `ProgressMetrics` bucketing.

## 4. Plan customization & persistence
- Edit `PlannedExercise` (sets/reps/rest/duration) and swap exercises in the plan.
- Persist edits to the active plan (currently `ExerciseDetailView` customizer is local-only).
- Reorder days, mark rest days.

## 5. HealthKit ✅ WRITE DONE (session 3)
- Writes finished workouts to Apple Health (`.traditionalStrengthTraining` via
  `HKWorkoutBuilder` + estimated active-energy sample) on completion.
- Files: `Core/Health/HealthKitService.swift` (`HealthWriting` protocol, mockable).
  Wired in `AppContainer.makeWorkoutPlayerViewModel` onComplete + `enableHealthSync()`.
- Profile screen: "Sync to Apple Health" toggle (requests share auth).
- Entitlement `Resources/FitnessPro.entitlements` (healthkit) + Info.plist usage strings.
- ⚠️ DEVICE: needs a real `DEVELOPMENT_TEAM` + HealthKit capability on the profile to
  run on hardware (builds fine on simulator unsigned). TODO: **read** steps/HR/energy.

## 6. Richer exercise media (optional upgrade)
- Current: free-exercise-db static images via AsyncImage (good, free, public domain).
- Upgrade path: ExerciseDB API (11k+ exercises **with GIFs/video**) — needs API key.
  Keep behind an `ExerciseProviding` impl so the dataset swap is local.
- Add offline image caching (e.g. URLCache tuning or a tiny disk cache).

## 7. Engagement ✅ MOSTLY DONE (session 3)
- ✅ **Local reminders** (`Core/Notifications/NotificationService.swift`,
  `NotificationScheduling`). Profile card: toggle + time picker + weekday chips,
  persisted as `ReminderSettings`, (re)scheduled via `UNCalendarNotificationTrigger`.
  `AppContainer.updateReminders` requests auth on enable.
- ✅ **Widget** (`Widgets/Extension/StreakWidget.swift`): streak/workouts/today focus,
  families small+medium+lock-screen (rect/circular). Reads shared App Group snapshot
  written by `AppState.publishWidgetSnapshot()` (`Widgets/Shared/WidgetSnapshot.swift`).
- ✅ **Live Activity** (`Widgets/Extension/RestTimerLiveActivity.swift`): Lock Screen +
  Dynamic Island rest timer, self-updating `Text(timerInterval:)`. Started/updated/ended
  by `Core/LiveActivity/LiveActivityController.swift`, hooked into `WorkoutPlayerViewModel`
  (start/beginRest/advance/stop). Attributes in `Widgets/Shared/WorkoutActivityAttributes.swift`.
- New target `FitnessProWidgetsExtension` in `project.yml` (embedded, App Group entitlement).
- ⚠️ DEVICE: App Group `group.com.ajaygirolkar.fitnesspro` + widget signing need a real
  `DEVELOPMENT_TEAM`/provisioning to run on hardware. Simulator builds unsigned OK.
- TODO: Onboarding "Quick Start" instant first session (partly done).

## 8. Nutrition (stretch)
- Calorie/macro targets from `FitnessProfile`; simple food log.

## 9. Polish & infra
- App icon art (placeholder appiconset is empty — add 1024px asset).
- Light-mode pass (app currently forces dark) + Dynamic Type + VoiceOver audit.
- Localization (extract strings).
- Settings: metric/imperial unit conversion (model has `unitSystem`, UI not wired).
- Empty/error states for image load failures.
- CI: `xcodegen generate && xcodebuild test` GitHub Action.

## 10. Tests to add
- `ClaudePlanGenerator` name→id resolution + DTO decoding (mock `AnthropicClient`).
- `PlanGeneratorService` fallback (AI throws → local plan returned).
- Snapshot/UI tests for onboarding and plan result.

## Reuse / extension notes
- New feature = `Features/<Name>/{Model,ViewModel,View,Service}`, `@MainActor @Observable`
  VM with a `ViewState` enum, protocol-first service, wire a factory in `AppContainer`.
- Plan engines are pluggable via `PlanGenerator`; exercise sources via `ExerciseProviding`.
- Run after changes: `xcodegen generate` then build/test on an iOS 17+ simulator.
