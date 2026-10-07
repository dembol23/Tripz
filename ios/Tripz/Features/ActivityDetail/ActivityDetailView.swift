import SwiftUI
import TripzKit
import TripzStorage

struct ActivityDetailView: View {
    @State private var viewModel: ActivityDetailViewModel
    
    init(activityId: UUID, repository: ActivityRepository) {
        _viewModel = State(initialValue: ActivityDetailViewModel(id: activityId, repository: repository))
    }
    
    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .task { await viewModel.load() }
    }
    
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .loading:
            ProgressView()
        case .notFound:
            ContentUnavailableView("Activity not found", systemImage: "questionmark.folder")
        case .failed(let message):
            ContentUnavailableView(
                "Couldn't load activity",
                systemImage: "exclamationmark.triangle",
                description: Text(message)
            )
        case .loaded(let activity):
            ActivityDetailContent(activity: activity)
        }
    }
}

private struct ActivityDetailContent: View {
    let activity: Activity
    private let mapModel: RouteMapModel?
    private let geometry: RouteGeometry?
    private let elevationSamples: [ElevationSample]
    @State private var selectedDistance: Double?
    @State private var sheetSelection: PresentationDetent = .fraction(0.9)
    @State private var isSheetPresented = false
        
    init(activity: Activity) {
        self.activity = activity
        if let route = activity.route, route.points.count >= 2 {
            let geometry = RouteGeometry(route: route)
            self.geometry = geometry
            self.elevationSamples = geometry.elevationSamples()
            self.mapModel = RouteMapModel(points: geometry.points)
        } else {
            self.geometry = nil
            self.elevationSamples = []
            self.mapModel = nil
        }
    }
    
    var body: some View {
        mapSection
            .ignoresSafeArea(edges: .all)
            .sheet(isPresented: $isSheetPresented) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(activity.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 24)
                            .padding(.bottom, 12)

                        Text(activity.start.formatted(date: .abbreviated, time: .shortened))
                            .font(.title3)
                            .foregroundStyle(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 12)
                        
                        List {
                            Section {
                                LabeledContent("Distance",
                                    value: Measurement(value: activity.distanceMeters, unit: UnitLength.meters)
                                        .formatted(.measurement(width: .abbreviated, usage: .road)))
                                LabeledContent("Duration",
                                    value: Duration.seconds(activity.durationSeconds)
                                        .formatted(.units(allowed: [.hours, .minutes], width: .abbreviated)))
                                
                                if let gain = activity.elevationGainMeters {
                                    LabeledContent("Elevation gain",
                                        value: Formatting.elevation(meters: gain))
                                }
                                if !elevationSamples.isEmpty {
                                    Section {
                                        ElevationChartView(samples: elevationSamples, selectedDistance: $selectedDistance)
                                    }
                                }
                            }
                            
                            if !activity.notes.isEmpty {
                                Section("Notes") {
                                    Text(activity.notes)
                                }
                            }
                        }
                        .listStyle(.plain)
                    }
                    .toolbar(.hidden, for: .navigationBar)
                }
                .presentationDetents(
                    [.height(95), .fraction(0.35), .large],
                    selection: $sheetSelection
                )
                .presentationCornerRadius(20)
                .presentationBackgroundInteraction(.enabled(upThrough: .fraction(0.35)))
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
            }
            .onAppear {
                isSheetPresented = true
            }
            .onDisappear {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    isSheetPresented = false
                }
            }
    }

    @ViewBuilder
    private var mapSection: some View {
        if let mapModel {
            RouteMapView(model: mapModel, highlight: highlightedCoordinate)
        } else {
            ContentUnavailableView("No route", systemImage: "map",
                description: Text("This activity has no recorded route."))
        }
    }
    
    private var highlightedCoordinate: CLLocationCoordinate2D? {
        guard let selectedDistance,
              let point = geometry?.point(atDistance: selectedDistance) else { return nil }
        return CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude)
    }
}

#Preview("Loaded Detail") {
    PreviewWrapper()
}

private struct PreviewWrapper: View {
    let activity = SampleData.pilatusHike()
    let repository = ActivityRepository(try! AppDatabase.inMemory())
    @State private var isReady = false
    
    var body: some View {
        NavigationStack {
            if isReady {
                ActivityDetailView(activityId: activity.id, repository: repository)
            } else {
                ProgressView()
            }
        }
        .task {
            // Save the sample activity to the in-memory database first
            try? await repository.save(activity)
            isReady = true
        }
    }
}
