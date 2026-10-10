import TripzStorage

#if DEBUG
extension ActivityStore {
    func addSampleActivity() async {
        try? await repository.save(SampleData.pilatusHike())
    }
}
#endif
