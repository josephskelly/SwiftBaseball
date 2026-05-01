import Foundation

/// A single pitch-level row from Baseball Savant's raw Statcast feed.
///
/// One value of this type represents one pitch, with strongly-typed fields for
/// the documented Savant CSV columns plus a ``raw`` escape hatch carrying the
/// original column → value strings (including any columns Savant adds in the
/// future without breaking the typed surface).
///
/// Fetched via:
/// - ``SwiftBaseball/statcastRaw(start:end:)``
/// - ``SwiftBaseball/statcastBatterRaw(playerId:start:end:)``
/// - ``SwiftBaseball/statcastPitcherRaw(playerId:start:end:)``
/// - ``SwiftBaseball/statcastGame(gamePk:)``
///
/// The CSV columns mirror those documented on
/// [Baseball Savant](https://baseballsavant.mlb.com/csv-docs).
/// Almost every typed field is optional because Savant emits empty cells for
/// non-applicable rows (a called strike has no `launch_speed`, an old game has
/// no `bat_speed`, etc.).
public struct StatcastPitch: Sendable, Equatable, Codable {
    // MARK: - Pitch identification

    /// 2-letter pitch code (e.g. `"FF"`, `"SL"`, `"CH"`).
    public let pitchType: String?
    /// Human-readable pitch name (e.g. `"4-Seam Fastball"`, `"Slider"`).
    public let pitchName: String?
    /// Date the pitch was thrown.
    public let gameDate: Date?
    /// Calendar year of the game.
    public let gameYear: Int?
    /// MLB game primary key.
    public let gamePk: Int?

    // MARK: - Players

    /// Pitcher's name as `"Last, First"`.
    public let playerName: String?
    /// MLB ID of the batter at the plate.
    public let batter: Int?
    /// MLB ID of the pitcher who threw the pitch.
    public let pitcher: Int?

    // MARK: - At-bat outcome

    /// Plate-appearance outcome (e.g. `"single"`, `"strikeout"`, `"field_out"`).
    /// Only populated on the final pitch of a PA.
    public let events: String?
    /// Pitch-level result (e.g. `"called_strike"`, `"foul"`, `"hit_into_play"`).
    public let description: String?
    /// Free-text description of the play.
    public let des: String?
    /// `"B"` (ball), `"S"` (strike), or `"X"` (in play).
    public let type: String?
    /// Fielder position (1–9) where the ball was hit, if in play.
    public let hitLocation: Int?
    /// Batted ball type (`"ground_ball"`, `"line_drive"`, `"fly_ball"`, `"popup"`).
    public let bbType: String?
    /// Balls before this pitch.
    public let balls: Int?
    /// Strikes before this pitch.
    public let strikes: Int?
    /// Strike-zone region (1–14) where the pitch crossed home plate.
    public let zone: Int?
    /// Batter handedness (`"L"` or `"R"`).
    public let stand: String?
    /// Pitcher handedness (`"L"` or `"R"`).
    public let pThrows: String?

    // MARK: - Game context

    /// Home team abbreviation.
    public let homeTeam: String?
    /// Away team abbreviation.
    public let awayTeam: String?
    /// Game type code (`"R"` regular season, `"S"` spring training, `"P"` postseason, etc.).
    public let gameType: String?
    /// Inning number.
    public let inning: Int?
    /// `"Top"` or `"Bot"`.
    public let inningTopBot: String?
    /// Outs recorded before this PA started.
    public let outsWhenUp: Int?
    /// MLB ID of the runner on first base, if any.
    public let on1B: Int?
    /// MLB ID of the runner on second base, if any.
    public let on2B: Int?
    /// MLB ID of the runner on third base, if any.
    public let on3B: Int?

    // MARK: - Pitch physics

    /// Velocity at release (mph).
    public let releaseSpeed: Double?
    /// Horizontal release position (feet from catcher's POV).
    public let releasePosX: Double?
    /// Vertical release position (feet).
    public let releasePosZ: Double?
    /// Release distance from rubber (feet).
    public let releasePosY: Double?
    /// Horizontal movement (feet).
    public let pfxX: Double?
    /// Vertical movement (feet).
    public let pfxZ: Double?
    /// Horizontal pitch location at home plate (feet from center).
    public let plateX: Double?
    /// Vertical pitch location at home plate (feet from ground).
    public let plateZ: Double?
    /// Initial velocity component, x-axis (ft/s).
    public let vx0: Double?
    /// Initial velocity component, y-axis (ft/s).
    public let vy0: Double?
    /// Initial velocity component, z-axis (ft/s).
    public let vz0: Double?
    /// Acceleration component, x-axis (ft/s²).
    public let ax: Double?
    /// Acceleration component, y-axis (ft/s²).
    public let ay: Double?
    /// Acceleration component, z-axis (ft/s²).
    public let az: Double?
    /// Top of the strike zone for this batter (feet).
    public let szTop: Double?
    /// Bottom of the strike zone for this batter (feet).
    public let szBot: Double?
    /// Perceived velocity adjusting for extension (mph).
    public let effectiveSpeed: Double?
    /// Spin rate at release (rpm).
    public let releaseSpinRate: Double?
    /// Pitcher's release extension toward the plate (feet).
    public let releaseExtension: Double?
    /// Spin axis (degrees, clock-face convention).
    public let spinAxis: Int?
    /// Legacy spin direction (degrees).
    public let spinDir: Double?

    // MARK: - Batted ball

    /// Distance traveled (feet) for the batted ball.
    public let hitDistanceSc: Int?
    /// Exit velocity off the bat (mph).
    public let launchSpeed: Double?
    /// Launch angle off the bat (degrees).
    public let launchAngle: Double?
    /// Launch-speed-angle category (1–6).
    public let launchSpeedAngle: Int?
    /// Hit coordinate, x-axis (Statcast field coordinate).
    public let hcX: Double?
    /// Hit coordinate, y-axis (Statcast field coordinate).
    public let hcY: Double?
    /// Estimated batting average from exit velocity and launch angle.
    public let estimatedBaUsingSpeedAngle: Double?
    /// Estimated wOBA from exit velocity and launch angle (xwOBA contact).
    public let estimatedWobaUsingSpeedAngle: Double?
    /// Estimated slugging from exit velocity and launch angle.
    public let estimatedSlgUsingSpeedAngle: Double?
    /// Linear-weights wOBA value for this PA outcome.
    public let wobaValue: Double?
    /// Denominator portion of the wOBA calculation.
    public let wobaDenom: Double?
    /// BABIP-eligible flag/value.
    public let babipValue: Double?
    /// ISO-eligible value.
    public let isoValue: Double?
    /// Hyper speed (adjusted exit velocity, mph).
    public let hyperSpeed: Double?

    // MARK: - Bat tracking (2024+)

    /// Bat speed at impact (mph).
    public let batSpeed: Double?
    /// Total swing path length (feet).
    public let swingLength: Double?
    /// Bat attack angle at impact (degrees).
    public let attackAngle: Double?
    /// Bat attack direction at impact (degrees).
    public let attackDirection: Double?
    /// Swing path tilt at impact (degrees).
    public let swingPathTilt: Double?
    /// Horizontal intercept distance (inches between ball and batter at contact).
    public let interceptBallMinusBatterPosXInches: Double?
    /// Vertical intercept distance (inches between ball and batter at contact).
    public let interceptBallMinusBatterPosYInches: Double?
    /// Pitcher arm angle at release (degrees).
    public let armAngle: Double?

    // MARK: - API break

    /// API break, vertical with gravity (inches).
    public let apiBreakZWithGravity: Double?
    /// API break, horizontal arm-side (inches).
    public let apiBreakXArm: Double?
    /// API break, horizontal batter-in (inches).
    public let apiBreakXBatterIn: Double?

    // MARK: - Fielding alignment

    /// Infield alignment (`"Standard"`, `"Strategic"`, `"Infield shift"`, etc.).
    public let ifFieldingAlignment: String?
    /// Outfield alignment (`"Standard"`, `"Strategic"`, `"4th outfielder"`, etc.).
    public let ofFieldingAlignment: String?
    /// MLB ID of catcher.
    public let fielder2: Int?
    /// MLB ID of first baseman.
    public let fielder3: Int?
    /// MLB ID of second baseman.
    public let fielder4: Int?
    /// MLB ID of third baseman.
    public let fielder5: Int?
    /// MLB ID of shortstop.
    public let fielder6: Int?
    /// MLB ID of left fielder.
    public let fielder7: Int?
    /// MLB ID of center fielder.
    public let fielder8: Int?
    /// MLB ID of right fielder.
    public let fielder9: Int?
    /// MLB ID of home plate umpire.
    public let umpire: Int?

    // MARK: - At-bat / pitch sequencing

    /// At-bat number within the game.
    public let atBatNumber: Int?
    /// Pitch number within the at-bat.
    public let pitchNumber: Int?

    // MARK: - Score state

    /// Home team score before the pitch.
    public let homeScore: Int?
    /// Away team score before the pitch.
    public let awayScore: Int?
    /// Batting team score before the pitch.
    public let batScore: Int?
    /// Fielding team score before the pitch.
    public let fldScore: Int?
    /// Home team score after the pitch.
    public let postHomeScore: Int?
    /// Away team score after the pitch.
    public let postAwayScore: Int?
    /// Batting team score after the pitch.
    public let postBatScore: Int?
    /// Fielding team score after the pitch.
    public let postFldScore: Int?
    /// Home minus away score (signed).
    public let homeScoreDiff: Int?
    /// Batting minus fielding score (signed).
    public let batScoreDiff: Int?

    // MARK: - Win expectancy

    /// Home team's win expectancy before the pitch (0–1).
    public let homeWinExp: Double?
    /// Batting team's win expectancy before the pitch (0–1).
    public let batWinExp: Double?
    /// Change in home-team win expectancy on this pitch (signed).
    public let deltaHomeWinExp: Double?
    /// Change in run expectancy on this pitch (signed).
    public let deltaRunExp: Double?
    /// Change in pitcher run expectancy (signed; negative = good for pitcher).
    public let deltaPitcherRunExp: Double?

    // MARK: - Player ages / sequencing

    /// Pitcher legacy age field.
    public let agePitLegacy: Int?
    /// Batter legacy age field.
    public let ageBatLegacy: Int?
    /// Pitcher age (years).
    public let agePit: Int?
    /// Batter age (years).
    public let ageBat: Int?
    /// Times through the order for this pitcher.
    public let nThruOrderPitcher: Int?
    /// Prior PAs this game between this batter and pitcher.
    public let nPriorPaThisGamePlayerAtBat: Int?
    /// Days since pitcher's previous game.
    public let pitcherDaysSincePrevGame: Int?
    /// Days since batter's previous game.
    public let batterDaysSincePrevGame: Int?
    /// Days until pitcher's next game.
    public let pitcherDaysUntilNextGame: Int?
    /// Days until batter's next game.
    public let batterDaysUntilNextGame: Int?

    // MARK: - Misc

    /// Savant pitch identifier (`sv_id`).
    public let svId: String?

    // MARK: - Escape hatch

    /// Original column → value strings as parsed from the CSV.
    ///
    /// Includes every header in the response, including any columns Savant adds in
    /// the future without a typed field above. Empty cells appear as empty strings.
    public let raw: [String: String]
}

// MARK: - Parser

/// Parses Baseball Savant raw Statcast CSV rows into ``StatcastPitch`` values.
enum StatcastPitchParser {
    /// Parses a Savant raw Statcast CSV string into ``StatcastPitch`` values.
    ///
    /// Uses `CSVParser.parse(_:preserveEmpty:)` with `preserveEmpty: true` so the
    /// `raw` escape hatch carries every header in the source CSV — including
    /// columns whose value is an empty cell on this row.
    static func parse(_ csv: String) -> [StatcastPitch] {
        CSVParser.parse(csv, preserveEmpty: true).map(parseRow)
    }

    /// Parses pre-extracted CSV row dictionaries. The caller is responsible for
    /// preserving empty cells if they want them carried through ``StatcastPitch/raw``.
    static func parse(rows: [[String: String]]) -> [StatcastPitch] {
        rows.map(parseRow)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    private static func intValue(_ row: [String: String], _ key: String) -> Int? {
        guard let value = row[key], !value.isEmpty else { return nil }
        return Int(value)
    }

    private static func doubleValue(_ row: [String: String], _ key: String) -> Double? {
        guard let value = row[key], !value.isEmpty else { return nil }
        return Double(value)
    }

    private static func stringValue(_ row: [String: String], _ key: String) -> String? {
        guard let value = row[key], !value.isEmpty else { return nil }
        return value
    }

    private static func dateValue(_ row: [String: String], _ key: String) -> Date? {
        guard let value = stringValue(row, key) else { return nil }
        return dateFormatter.date(from: value)
    }

    private static func parseRow(_ row: [String: String]) -> StatcastPitch {
        StatcastPitch(
            pitchType: stringValue(row, "pitch_type"),
            pitchName: stringValue(row, "pitch_name"),
            gameDate: dateValue(row, "game_date"),
            gameYear: intValue(row, "game_year"),
            gamePk: intValue(row, "game_pk"),
            playerName: stringValue(row, "player_name"),
            batter: intValue(row, "batter"),
            pitcher: intValue(row, "pitcher"),
            events: stringValue(row, "events"),
            description: stringValue(row, "description"),
            des: stringValue(row, "des"),
            type: stringValue(row, "type"),
            hitLocation: intValue(row, "hit_location"),
            bbType: stringValue(row, "bb_type"),
            balls: intValue(row, "balls"),
            strikes: intValue(row, "strikes"),
            zone: intValue(row, "zone"),
            stand: stringValue(row, "stand"),
            pThrows: stringValue(row, "p_throws"),
            homeTeam: stringValue(row, "home_team"),
            awayTeam: stringValue(row, "away_team"),
            gameType: stringValue(row, "game_type"),
            inning: intValue(row, "inning"),
            inningTopBot: stringValue(row, "inning_topbot"),
            outsWhenUp: intValue(row, "outs_when_up"),
            on1B: intValue(row, "on_1b"),
            on2B: intValue(row, "on_2b"),
            on3B: intValue(row, "on_3b"),
            releaseSpeed: doubleValue(row, "release_speed"),
            releasePosX: doubleValue(row, "release_pos_x"),
            releasePosZ: doubleValue(row, "release_pos_z"),
            releasePosY: doubleValue(row, "release_pos_y"),
            pfxX: doubleValue(row, "pfx_x"),
            pfxZ: doubleValue(row, "pfx_z"),
            plateX: doubleValue(row, "plate_x"),
            plateZ: doubleValue(row, "plate_z"),
            vx0: doubleValue(row, "vx0"),
            vy0: doubleValue(row, "vy0"),
            vz0: doubleValue(row, "vz0"),
            ax: doubleValue(row, "ax"),
            ay: doubleValue(row, "ay"),
            az: doubleValue(row, "az"),
            szTop: doubleValue(row, "sz_top"),
            szBot: doubleValue(row, "sz_bot"),
            effectiveSpeed: doubleValue(row, "effective_speed"),
            releaseSpinRate: doubleValue(row, "release_spin_rate"),
            releaseExtension: doubleValue(row, "release_extension"),
            spinAxis: intValue(row, "spin_axis"),
            spinDir: doubleValue(row, "spin_dir"),
            hitDistanceSc: intValue(row, "hit_distance_sc"),
            launchSpeed: doubleValue(row, "launch_speed"),
            launchAngle: doubleValue(row, "launch_angle"),
            launchSpeedAngle: intValue(row, "launch_speed_angle"),
            hcX: doubleValue(row, "hc_x"),
            hcY: doubleValue(row, "hc_y"),
            estimatedBaUsingSpeedAngle: doubleValue(row, "estimated_ba_using_speedangle"),
            estimatedWobaUsingSpeedAngle: doubleValue(row, "estimated_woba_using_speedangle"),
            estimatedSlgUsingSpeedAngle: doubleValue(row, "estimated_slg_using_speedangle"),
            wobaValue: doubleValue(row, "woba_value"),
            wobaDenom: doubleValue(row, "woba_denom"),
            babipValue: doubleValue(row, "babip_value"),
            isoValue: doubleValue(row, "iso_value"),
            hyperSpeed: doubleValue(row, "hyper_speed"),
            batSpeed: doubleValue(row, "bat_speed"),
            swingLength: doubleValue(row, "swing_length"),
            attackAngle: doubleValue(row, "attack_angle"),
            attackDirection: doubleValue(row, "attack_direction"),
            swingPathTilt: doubleValue(row, "swing_path_tilt"),
            interceptBallMinusBatterPosXInches: doubleValue(row, "intercept_ball_minus_batter_pos_x_inches"),
            interceptBallMinusBatterPosYInches: doubleValue(row, "intercept_ball_minus_batter_pos_y_inches"),
            armAngle: doubleValue(row, "arm_angle"),
            apiBreakZWithGravity: doubleValue(row, "api_break_z_with_gravity"),
            apiBreakXArm: doubleValue(row, "api_break_x_arm"),
            apiBreakXBatterIn: doubleValue(row, "api_break_x_batter_in"),
            ifFieldingAlignment: stringValue(row, "if_fielding_alignment"),
            ofFieldingAlignment: stringValue(row, "of_fielding_alignment"),
            fielder2: intValue(row, "fielder_2"),
            fielder3: intValue(row, "fielder_3"),
            fielder4: intValue(row, "fielder_4"),
            fielder5: intValue(row, "fielder_5"),
            fielder6: intValue(row, "fielder_6"),
            fielder7: intValue(row, "fielder_7"),
            fielder8: intValue(row, "fielder_8"),
            fielder9: intValue(row, "fielder_9"),
            umpire: intValue(row, "umpire"),
            atBatNumber: intValue(row, "at_bat_number"),
            pitchNumber: intValue(row, "pitch_number"),
            homeScore: intValue(row, "home_score"),
            awayScore: intValue(row, "away_score"),
            batScore: intValue(row, "bat_score"),
            fldScore: intValue(row, "fld_score"),
            postHomeScore: intValue(row, "post_home_score"),
            postAwayScore: intValue(row, "post_away_score"),
            postBatScore: intValue(row, "post_bat_score"),
            postFldScore: intValue(row, "post_fld_score"),
            homeScoreDiff: intValue(row, "home_score_diff"),
            batScoreDiff: intValue(row, "bat_score_diff"),
            homeWinExp: doubleValue(row, "home_win_exp"),
            batWinExp: doubleValue(row, "bat_win_exp"),
            deltaHomeWinExp: doubleValue(row, "delta_home_win_exp"),
            deltaRunExp: doubleValue(row, "delta_run_exp"),
            deltaPitcherRunExp: doubleValue(row, "delta_pitcher_run_exp"),
            agePitLegacy: intValue(row, "age_pit_legacy"),
            ageBatLegacy: intValue(row, "age_bat_legacy"),
            agePit: intValue(row, "age_pit"),
            ageBat: intValue(row, "age_bat"),
            nThruOrderPitcher: intValue(row, "n_thruorder_pitcher"),
            nPriorPaThisGamePlayerAtBat: intValue(row, "n_priorpa_thisgame_player_at_bat"),
            pitcherDaysSincePrevGame: intValue(row, "pitcher_days_since_prev_game"),
            batterDaysSincePrevGame: intValue(row, "batter_days_since_prev_game"),
            pitcherDaysUntilNextGame: intValue(row, "pitcher_days_until_next_game"),
            batterDaysUntilNextGame: intValue(row, "batter_days_until_next_game"),
            svId: stringValue(row, "sv_id"),
            raw: row
        )
    }
}
