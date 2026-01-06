# Workout Tracking App Enhancement Plan

## Overview
Enhance your SwiftUI workout tracking app with improved workout experience, data visualization, and usability features.

**Current Stack**: SwiftUI + SwiftData, iOS 17+
**Project Location**: `/Users/lenovo1/workspace/workout-app/workout-app/`

---

## Implementation Phases

### PHASE 1: Foundation & Quick Wins (Week 1-2)

#### 1.1 Verify Data Persistence ✅
**Status**: Already working! SwiftData configured correctly.
- Persistence verified in `workout_appApp.swift:13-26`
- No code changes needed, just testing

#### 1.2 Unit Conversion (kg/lbs) ✅
**Time**: 2-3 hours | **Value**: High

**New Files**:
- `Models/UserPreferences.swift` - Settings model with WeightUnit enum
- `Utilities/UnitConverter.swift` - Conversion helpers
- `Views/Settings/SettingsView.swift` - Settings screen

**Modified Files**:
- `ContentView.swift` - Add Settings tab
- `Views/Logging/LogExerciseView.swift` - Dynamic unit labels
- `Views/Metrics/MetricsView.swift` - Convert display units

**Approach**: Store all weights as pounds internally, convert on display/input based on preference

#### 1.3 Exercise Search  ✅
**Time**: 2-3 hours | **Value**: High

**Modified Files**:
- `Views/Home/EditRoutineView.swift` - Add `.searchable()` modifier

**Implementation**: Filter exercises by name and muscle group using SwiftUI searchable

#### 1.4 Pre-loaded Exercise Database ✅
**Time**: 4-6 hours | **Value**: Very High

**New Files**:
- `Data/PreloadedExercises.json` - 100+ exercises with instructions
- `Utilities/DatabaseSeeder.swift` - One-time seeding logic

**Modified Files**:
- `workout_appApp.swift` - Call seeder on first launch

**Exercise Categories**: Chest, Back, Legs, Shoulders, Arms, Core, Cardio

---

### PHASE 2: Workout Experience Improvements (Week 3-4)

#### 2.1 Last Attempt Display 🎯 HIGH PRIORITY ✅ (Has some more improvements pending in Backlog)
**Time**: 4-5 hours | **Value**: Very High

**New Data Model** (Breaking Change):
- `Models/SetLog.swift` - Track individual sets instead of aggregated workout
  ```swift
  @Model final class SetLog {
      var setNumber: Int
      var reps: Int
      var weight: Double
      var notes: String?
      var date: Date
      var exercise: Exercise?
  }
  ```

**Modified Files**:
- `Models/Exercise.swift` - Add SetLog relationship
- `Views/Logging/LogExerciseView.swift` - **Complete rewrite** for set-by-set logging
- `workout_appApp.swift` - Update schema to include SetLog

**New Views**:
- `Views/Logging/SetEntryRow.swift` - Individual set entry with greyscale last attempt

**UI Design**: When entering Set 1, display previous Set 1 data in greyscale (lighter text color)

#### 2.2 Rest Timer
**Time**: 3-4 hours | **Value**: High

**New Files**:
- `Views/Logging/RestTimerView.swift` - Circular timer overlay
- `Utilities/TimerManager.swift` - Timer logic with notifications

**Modified Files**:
- `Views/Logging/LogExerciseView.swift` - Show timer sheet after set completion
- `Models/UserPreferences.swift` - Store default rest duration

**Features**: Circular progress, skip/done buttons, sound notification

#### 2.3 Set Notes
**Time**: 1-2 hours | **Value**: Medium

**Implementation**: Already included in SetLog model above - just add TextField in UI

#### 2.4 Exercise Instructions
**Time**: 3-4 hours | **Value**: Medium

**Modified Files**:
- `Models/Exercise.swift` - Add `instructions`, `formCues`, `videoURL` fields

**New Views**:
- `Views/Home/ExerciseDetailView.swift` - Full exercise detail screen

**Modified Files**:
- `Views/Home/ExerciseRowView.swift` - Make tappable to show details
- `Views/Home/AddExerciseView.swift` - Add instructions field

---

### PHASE 3: Better Data Visualization (Week 5-6)

#### 3.1 Per-Exercise Trend Charts
**Time**: 4-5 hours | **Value**: High

**New Views**:
- `Views/Metrics/ExerciseDetailMetricsView.swift`

**Charts to Add**:
- Weight progression over time (line chart)
- Volume trend (area chart)
- Max weight by rep range (bar chart)

**Modified Files**:
- `Views/Metrics/MetricsView.swift` - Make history items tappable

#### 3.2 Calendar View
**Time**: 5-6 hours | **Value**: Very High

**New Views**:
- `Views/Metrics/WorkoutCalendarView.swift`

**Features**:
- Month view with workout indicators (blue dots on workout days)
- Tap date to see workout summary
- Visual motivation tool

**Implementation**: SwiftUI LazyVGrid for calendar layout

#### 3.3 Muscle Group Breakdown
**Time**: 3-4 hours | **Value**: Medium-High

**New Views**:
- `Views/Metrics/MuscleGroupBreakdownView.swift`

**Charts**:
- Pie chart of volume by muscle group
- Bar chart of workout frequency
- Weekly balance view

---

### PHASE 4: Advanced Features (Week 7-8)

#### 4.1 Workout Templates
**Time**: 6-8 hours | **Value**: High

**New Model**:
- `Models/WorkoutTemplate.swift` - Save/load complete workouts

**New Views**:
- `Views/Templates/TemplateLibraryView.swift`
- `Views/Templates/SaveTemplateView.swift`

**Modified Files**:
- `ContentView.swift` - Add Templates tab
- `Views/Home/RoutineView.swift` - "Load Template" button

**Features**: Save current workout, load to any day, template categories

#### 4.2 Workout Reminders
**Time**: 3-4 hours | **Value**: Medium-High

**New Files**:
- `Utilities/NotificationManager.swift`

**Modified Files**:
- `Views/Settings/SettingsView.swift` - Notification settings
- `Models/UserPreferences.swift` - Store preferences

**iOS Permissions**: Request notification authorization

#### 4.3 Superset Support (Optional)
**Time**: 6-8 hours | **Value**: High | **Complexity**: High

**New Model**:
- `Models/ExerciseGroup.swift` - Group exercises into supersets/circuits

**Modified Files**:
- `Models/Routine.swift` - Change from `[Exercise]` to `[ExerciseGroup]`
- Multiple view updates

**Note**: This is a breaking change requiring data migration - recommend implementing last

---

## Critical Files

### Highest Priority (Phase 2):
1. **`Models/SetLog.swift`** (NEW) - Foundation for set-by-set tracking
2. **`Views/Logging/LogExerciseView.swift`** - Complete rewrite for new logging flow
3. **`Models/UserPreferences.swift`** (NEW) - Central settings storage

### Core Infrastructure:
4. **`workout_appApp.swift`** - Update schema with new models
5. **`Models/Exercise.swift`** - Add relationships and fields

### Analytics Hub:
6. **`Views/Metrics/MetricsView.swift`** - Expand for new visualizations

---

## Data Migration Strategy

### Schema Evolution:
```swift
// Phase 1: Current
Schema([Exercise, WorkoutLog, Routine])

// Phase 2: Add SetLog + Preferences
Schema([Exercise, WorkoutLog, SetLog, Routine, UserPreferences])

// Phase 4: Add Templates
Schema([Exercise, WorkoutLog, SetLog, Routine, UserPreferences, WorkoutTemplate])
```

**SwiftData handles automatic migration** for:
- Adding new models
- Adding optional properties
- New relationships

**Manual migration required** for:
- Routine restructure (if implementing supersets)

---

## Recommended Implementation Order

**Week 1-2**: Foundation
1. Unit conversion + Settings tab
2. Exercise search
3. Pre-load exercise database

**Week 3-4**: Core Logging
4. SetLog model + migration
5. Last attempt display
6. Rest timer
7. Set notes

**Week 5-6**: Analytics
8. Per-exercise charts
9. Calendar view
10. Muscle group breakdown

**Week 7-8**: Advanced
11. Workout templates
12. Notifications
13. Exercise instructions

---

## Key Design Decisions

### Last Attempt Display
- Query most recent SetLog for same exercise + set number
- Display in greyscale (`.foregroundStyle(.secondary)`)
- Show: "Last: 3x12 @ 135 lbs" below input fields

### Unit Conversion
- Store internally as pounds (no migration needed)
- Convert on display/input via UserPreferences
- Toggle in Settings tab

### Rest Timer
- Auto-start after logging set (if enabled in preferences)
- Sheet presentation with circular progress
- Local notification on completion

### Data Persistence
- Already working via SwiftData
- If issues: check `isStoredInMemoryOnly: false` in workout_appApp.swift

---

## Success Metrics
- ✅ Data persists across app restarts
- ✅ Users see last attempt when logging sets
- ✅ Rest timer helps with workout pacing
- ✅ Calendar shows workout consistency
- ✅ Charts show progressive overload trends

**Total Estimated Time**: 60-75 hours (1.5-2 months part-time)

---

## Backlog

### Core Improvements

#### 1. Auto-populate sets from last workout
**Description**: When creating a new workout for an exercise, automatically show the same number of sets as the last workout, with each set pre-filled with the previous attempt data (weight, reps) in greyscale.

**Current State**:
- Currently shows previous data per set number if available
- Does not auto-create set rows based on last workout
- User must manually add sets one by one

**Desired Behavior**:
- If last workout had 4 sets, automatically create 4 set rows
- Each row shows previous attempt data (e.g., Set 1: "12kg × 12", Set 2: "12kg × 10", etc.)
- User can edit values or add/remove sets as needed
- Makes workout logging faster and maintains consistency

**Implementation Notes**:
- Query last WorkoutLog for exercise
- Auto-generate SetEntry array based on previous set count
- Pre-fill weight/reps fields with previous values (in greyscale/placeholder style)
- Allow easy modification and set addition/removal

**Priority**: High
**Estimated Time**: 2-3 hours

#### 2. Auto-select current day of week
**Description**: When opening the app, automatically highlight and select the current day of the week in the day selector, so users see today's routine by default.

**Current State**:
- App opens to a default day (possibly Monday or last selected day)
- User must manually tap to switch to today's day
- No visual indication of which day is today

**Desired Behavior**:
- On app launch, automatically select today's day (e.g., if it's Tuesday, show Tuesday's routine)
- Highlight current day differently (e.g., different color, bold, or indicator)
- User can still manually switch to other days
- Improves UX by showing relevant routine immediately

**Implementation Notes**:
- Use `Calendar.current.component(.weekday, from: Date())` to get current day
- Map weekday number (1-7) to day name ("Sunday"-"Saturday")
- Set `selectedDay` state to current day on view appear
- Add visual indicator (e.g., blue background) for today's day in DaySelectorView

**Priority**: Medium
**Estimated Time**: 1 hour

---

### Data & User Features

#### 3. Data export/import (backup/restore)
**Description**: Allow users to export their workout data and import it back for backup/restore purposes.

**Features**:
- Export all data (exercises, routines, workout logs) to JSON/CSV
- Import data from backup file
- Cloud backup option (iCloud Drive)
- Restore data after app reinstall

**Priority**: Medium
**Estimated Time**: 4-6 hours

#### 4. Onboarding flow for new users
**Description**: Welcome screen with tutorial/guide for first-time users to understand app features.

**Features**:
- Welcome screens explaining key features
- Quick setup (units preference, initial exercises)
- Sample routine/workout demo
- Skip option for advanced users

**Priority**: Medium
**Estimated Time**: 3-4 hours

#### 5. Share workouts with friends (Community Feature)
**Description**: Social features to share workout progress and routines with friends.

**Features**:
- Share workout summary (text/image)
- Share routines with others
- Import shared routines
- Leaderboards (optional)
- Workout challenges (optional)

**Priority**: Low
**Estimated Time**: 15-20 hours

---

### Performance & Technical Improvements

#### 6. Performance optimizations
**Description**: Improve app performance for faster data loading and smoother scrolling.

**Optimizations**:
- Lazy loading for large exercise lists
- Query optimization for SwiftData
- Image/icon caching
- Reduce view re-renders
- Profile and fix performance bottlenecks

**Priority**: Medium
**Estimated Time**: 4-6 hours

#### 7. Offline mode / data sync
**Description**: Ensure app works fully offline and syncs when connection available.

**Features**:
- Full offline functionality (already works with SwiftData)
- Queue sync operations when offline
- Conflict resolution for sync
- Sync status indicator

**Priority**: Low
**Estimated Time**: 8-10 hours

#### 8. Better error handling
**Description**: Improve error messages and graceful failure handling throughout the app.

**Improvements**:
- User-friendly error messages
- Retry mechanisms for failed operations
- Error logging for debugging
- Graceful degradation when features unavailable
- Input validation improvements

**Priority**: Medium
**Estimated Time**: 3-4 hours

---

### Platform Expansion

#### 9. Apple Watch companion app
**Description**: Standalone Apple Watch app for quick workout logging.

**Features**:
- View today's routine
- Quick set logging
- Rest timer on watch
- Complications for quick access
- Sync with iPhone app

**Priority**: Low
**Estimated Time**: 20-25 hours

#### 10. Multi-device sync (iCloud)
**Description**: Sync workout data across multiple iOS devices using iCloud.

**Features**:
- iCloud CloudKit integration
- Automatic background sync
- Conflict resolution
- Works across iPhone, iPad, Mac

**Priority**: Medium-High
**Estimated Time**: 8-12 hours

#### 11. Progressive web app version
**Description**: Web-based version accessible from any browser.

**Features**:
- Responsive web design
- PWA for offline capability
- Cross-platform (Windows, Android via browser)
- Data sync with native app

**Priority**: Low
**Estimated Time**: 30-40 hours

#### 12. iPad optimization
**Description**: Optimize UI/UX for iPad's larger screen.

**Features**:
- Multi-column layout
- Split view support
- Drag-and-drop for routine building
- Keyboard shortcuts
- Optimized charts and visualizations

**Priority**: Medium
**Estimated Time**: 8-10 hours

#### 13. Widget support
**Description**: Home screen widgets for quick access and motivation.

**Widget Types**:
- Today's routine widget
- Workout streak counter
- Quick log last exercise
- Weekly volume chart
- Motivational stats

**Priority**: Medium
**Estimated Time**: 6-8 hours
