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

## 3. Progress tracking
- Persist completed workouts; weekly streak, volume, weight log.
- Swift Charts: weight trend, sessions/week, calories.
- Files: `Features/Progress/`. New `WorkoutLog` model + store.

## 4. Plan customization & persistence
- Edit `PlannedExercise` (sets/reps/rest/duration) and swap exercises in the plan.
- Persist edits to the active plan (currently `ExerciseDetailView` customizer is local-only).
- Reorder days, mark rest days.

## 5. HealthKit
- Read steps, heart rate, active energy; write workouts.
- `HKHealthStore` permission flow + `Core/Health/HealthKitService`.

## 6. Richer exercise media (optional upgrade)
- Current: free-exercise-db static images via AsyncImage (good, free, public domain).
- Upgrade path: ExerciseDB API (11k+ exercises **with GIFs/video**) — needs API key.
  Keep behind an `ExerciseProviding` impl so the dataset swap is local.
- Add offline image caching (e.g. URLCache tuning or a tiny disk cache).

## 7. Engagement
- Local notifications / workout reminders (`UNUserNotificationCenter`).
- Home/Lock-screen Widgets + Live Activity during a workout.
- Onboarding "Quick Start" → instant first session without full quiz (partly done).

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
