public struct StatsBookKit_scoping {
    // add typealiass so we can import but still get IGRF from here
    // because module importing vs current module doesn't easily support
    // module scoping
    public typealias _IGRF = IGRF
    public typealias _Score = Score
    public typealias _Penalties = Penalties
    public typealias _Lineups = Lineups
}
