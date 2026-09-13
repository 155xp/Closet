import SwiftUI
import SwiftData

struct OutfitCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \DailyOutfit.day) private var outfits: [DailyOutfit]
    @State private var selectedWeek = 0
    @State private var weeks = -1...1
    @State private var referenceDate = Date.now

    private var calendar: Calendar { .current }
    private var firstDay: Date { calendar.dateInterval(of: .weekOfYear, for: referenceDate)!.start }

    private func weekStart(_ offset: Int) -> Date {
        calendar.date(byAdding: .weekOfYear, value: offset, to: firstDay)!
    }

    private func move(to offset: Int) {
        weeks = min(weeks.lowerBound, offset - 1)...max(weeks.upperBound, offset + 1)
        selectedWeek = offset
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                HStack {
                    Button("Previous week", systemImage: "chevron.left") { move(to: selectedWeek - 1) }
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                    Spacer()
                    let start = weekStart(selectedWeek)
                    let end = calendar.date(byAdding: .day, value: 6, to: start)!
                    Text("\(start.formatted(.dateTime.month(.abbreviated).day())) – \(end.formatted(.dateTime.month(.abbreviated).day().year()))")
                        .font(.subheadline.weight(.medium))
                        .accessibilityIdentifier("calendarWeekTitle")
                    Spacer()
                    Button("Next week", systemImage: "chevron.right") { move(to: selectedWeek + 1) }
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
                .tint(.primary)
                .padding(.horizontal, 12)

                TabView(selection: $selectedWeek) {
                    ForEach(Array(weeks), id: \.self) { offset in
                        week(starting: weekStart(offset))
                            .tag(offset)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .accessibilityIdentifier("calendarWeeks")
                .onChange(of: selectedWeek) { _, value in move(to: value) }
            }
            .background(ClosetStyle.background)
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Today") {
                        referenceDate = .now
                        move(to: 0)
                    }
                    .accessibilityIdentifier("calendarTodayButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("doneCalendarButton")
                }
            }
        }
    }

    private func week(starting start: Date) -> some View {
        GeometryReader { geometry in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    ForEach(0..<7) { index in
                        let day = calendar.date(byAdding: .day, value: index, to: start)!
                        let outfit = DailyOutfit.on(day, in: outfits)
                        HStack(spacing: 16) {
                            VStack(spacing: 3) {
                                Text(day.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(day.formatted(.dateTime.day()))
                                    .font(.title3.weight(calendar.isDateInToday(day) ? .bold : .regular))
                                    .foregroundStyle(calendar.isDateInToday(day) ? Color.accentColor : .primary)
                            }
                            .frame(width: 44)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(day.formatted(date: .complete, time: .omitted))

                            if let outfit {
                                ForEach(ClothingCategory.allCases) { category in
                                    if let piece = outfit.pieces.first(where: { $0.categoryValue == category.rawValue }),
                                       let image = UIImage(data: piece.photo) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 64)
                                            .accessibilityLabel(piece.name)
                                            .accessibilityIdentifier("calendarPhoto_\(category.rawValue)")
                                    }
                                }
                            } else {
                                Text("No outfit")
                                    .font(.subheadline)
                                    .foregroundStyle(.tertiary)
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(height: max(80, geometry.size.height / 7))
                        .background(calendar.isDateInToday(day) ? Color.primary.opacity(0.035) : .clear)
                        .overlay(alignment: .bottom) {
                            Divider().padding(.leading, 80)
                        }
                    }
                }
            }
        }
    }
}
