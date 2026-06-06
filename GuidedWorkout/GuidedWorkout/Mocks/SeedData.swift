//
//  Untitled.swift
//  GuidedWorkout
//
//  Created by Sahithi Mucchala on 06/06/26.
//

import Foundation

nonisolated enum SeedData {
    static let todaySession = WorkoutSession(
        id: "session_mobility_001",
        scheduleId: "schedule_today_2026_06_02",
        workoutId: "workout_lower_back_reset",
        title: "Lower Back Reset",
        subtitle: "A calm mobility routine for stiffness and posture",
        estimatedMinutes: 22,
        restSecondsBetweenExercises: 30,
        exercises: [
            Exercise(
                id: "ex_cat_cow",
                title: "Cat-Cow Mobility",
                area: "Spine",
                difficulty: .beginner,
                target: .time(seconds: 45),
                sets: 2,
                safetyNote: "Keep movement slow and comfortable.",
                thumbnailURL: URL(string: "https://example.com/thumbnails/cat-cow.jpg")!,
                videoURL: URL(string: "https://example.com/videos/cat-cow.m3u8")!,
                instructions: [
                    "Start on all fours with wrists under shoulders and knees under hips.",
                    "Inhale, drop the belly and lift the chest into Cow.",
                    "Exhale, round the spine and tuck the chin into Cat.",
                    "Flow continuously, matching breath to movement."
                ]
            ),
            Exercise(
                id: "ex_glute_bridge",
                title: "Glute Bridge",
                area: "Hips",
                difficulty: .beginner,
                target: .reps(count: 12),
                sets: 3,
                safetyNote: "Stop if sharp back or hip pain appears.",
                thumbnailURL: URL(string: "https://example.com/thumbnails/glute-bridge.jpg")!,
                videoURL: URL(string: "https://example.com/videos/glute-bridge.m3u8")!,
                instructions: [
                    "Lie on your back with knees bent and feet flat on the floor.",
                    "Press through the heels and squeeze the glutes to lift the hips.",
                    "Pause briefly at the top, then lower with control.",
                    "Keep ribs down and avoid over-arching the lower back."
                ]
            ),
            Exercise(
                id: "ex_dead_bug",
                title: "Dead Bug",
                area: "Core",
                difficulty: .intermediate,
                target: .reps(count: 10),
                sets: 3,
                safetyNote: "Avoid arching the lower back.",
                thumbnailURL: URL(string: "https://example.com/thumbnails/dead-bug.jpg")!,
                videoURL: URL(string: "https://example.com/videos/dead-bug.m3u8")!,
                instructions: [
                    "Lie on your back with arms reaching toward the ceiling and knees stacked over hips.",
                    "Slowly extend the opposite arm and leg toward the floor.",
                    "Keep the lower back pressed gently into the mat throughout.",
                    "Return and alternate sides for one rep."
                ]
            ),
            Exercise(
                id: "ex_quad_stretch",
                title: "Standing Quad Stretch",
                area: "Thighs",
                difficulty: .beginner,
                target: .time(seconds: 30),
                sets: 2,
                safetyNote: "Use support for balance.",
                thumbnailURL: URL(string: "https://example.com/thumbnails/quad-stretch.jpg")!,
                videoURL: URL(string: "https://example.com/videos/quad-stretch.m3u8")!,
                instructions: [
                    "Stand tall and hold a wall or chair for balance.",
                    "Bend one knee and bring the heel toward the glute.",
                    "Hold the ankle gently and keep knees aligned.",
                    "Switch sides halfway through the set."
                ]
            ),
            Exercise(
                id: "ex_band_rows",
                title: "Resistance Band Rows",
                area: "Upper back",
                difficulty: .intermediate,
                target: .reps(count: 15),
                sets: 3,
                safetyNote: "Keep shoulders relaxed.",
                thumbnailURL: URL(string: "https://example.com/thumbnails/band-rows.jpg")!,
                videoURL: URL(string: "https://example.com/videos/band-rows.m3u8")!,
                instructions: [
                    "Anchor the band at chest height and hold a handle in each hand.",
                    "Step back to create tension and stand tall with a soft knee.",
                    "Pull the handles toward your ribs, squeezing the shoulder blades.",
                    "Release slowly with control."
                ]
            )
        ]
    )
}
