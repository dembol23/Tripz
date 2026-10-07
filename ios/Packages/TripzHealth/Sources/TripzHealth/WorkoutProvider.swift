public protocol WorkoutProvider: Sendable {
    func requestAccess() async throws

    func hikingWorkouts() async throws -> [HealthWorkout]
}
