//
//  RunnerSprites.swift
//  NotchGames
//
//  Created by Filippo Cilia on 11/3/26.
//

/// The runner's pixel art, as rows where `#` is lit and `.` is dark. Sizes match `RunnerModel` and `RunnerObstacle`.
nonisolated enum RunnerSprites {
    static let skater = [
        "...##...",
        "...##...",
        "..####..",
        ".#.##.#.",
        "...##...",
        "...##...",
        "..#..#..",
        "..#..#..",
        ".#....#.",
        "########",
        ".#....#."
    ]
    static let ducking = [
        "..##....",
        ".#####..",
        "#######.",
        ".#...#..",
        "########",
        ".#....#."
    ]
    static let cone = [
        "..#..",
        "..#..",
        ".###.",
        ".###.",
        "#####",
        "#####"
    ]
    static let bench = [
        "################",
        "################",
        ".#............#.",
        ".#............#.",
        ".#............#."
    ]
    /// Two frames, wings up and down.
    static let pigeon = [
        [
            ".#...#.",
            "..#.#..",
            ".######",
            "#####.."
        ],
        [
            ".......",
            "....###",
            "#######",
            ".#####."
        ]
    ]
    static let cart = [
        "#......#",
        "########",
        "#......#",
        "########",
        ".#....#.",
        ".#....#."
    ]
}
