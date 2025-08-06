//
//  ContentView.swift
//  Espresso Trainer
//
//  Created by Michael Zhou on 8/6/25.
//

import SwiftUI

// MARK: - Data Models
struct CoffeeBean: Identifiable, Codable {
    let id: UUID
    let name: String
    let roastLevel: RoastLevel
    let origin: String
    let roastDate: Date
    
    init(name: String, roastLevel: RoastLevel, origin: String, roastDate: Date) {
        self.id = UUID()
        self.name = name
        self.roastLevel = roastLevel
        self.origin = origin
        self.roastDate = roastDate
    }
    
    var daysSinceRoast: Int {
        let calendar = Calendar.current
        let days = calendar.dateComponents([.day], from: roastDate, to: Date()).day ?? 0
        return days
    }
    
    var freshnessDescription: String {
        let days = daysSinceRoast
        switch days {
        case 0...3:
            return "Very Fresh"
        case 4...7:
            return "Fresh"
        case 8...14:
            return "Good"
        case 15...21:
            return "Fair"
        default:
            return "Old"
        }
    }
}

enum RoastLevel: String, CaseIterable, Codable {
    case light = "Light"
    case medium = "Medium"
    case dark = "Dark"
}

struct EspressoShot: Identifiable, Codable {
    let id: UUID
    let date: Date
    let grindSetting: Double
    let coffeeBean: CoffeeBean
    let dose: Double
    let yield: Double
    let shotTime: Double
    let tasteNotes: String
    
    var extractionRatio: Double {
        return yield / dose
    }
    
    init(date: Date, grindSetting: Double, coffeeBean: CoffeeBean, dose: Double, yield: Double, shotTime: Double, tasteNotes: String) {
        self.id = UUID()
        self.date = date
        self.grindSetting = grindSetting
        self.coffeeBean = coffeeBean
        self.dose = dose
        self.yield = yield
        self.shotTime = shotTime
        self.tasteNotes = tasteNotes
    }
}

// MARK: - Bean Management State
class BeanManager: ObservableObject {
    @Published var beans: [CoffeeBean] = []
    
    init() {
        loadBeans()
    }
    
    func addBean(_ bean: CoffeeBean) {
        beans.append(bean)
        saveBeans()
    }
    
    func deleteBean(_ bean: CoffeeBean) {
        beans.removeAll { $0.id == bean.id }
        saveBeans()
    }
    
    private func saveBeans() {
        if let encoded = try? JSONEncoder().encode(beans) {
            UserDefaults.standard.set(encoded, forKey: "coffeeBeans")
        }
    }
    
    private func loadBeans() {
        if let data = UserDefaults.standard.data(forKey: "coffeeBeans"),
           let decoded = try? JSONDecoder().decode([CoffeeBean].self, from: data) {
            beans = decoded
        }
    }
}

// MARK: - Bean Creation State
class BeanCreationState: ObservableObject {
    @Published var origin: String = ""
    @Published var roastLevel: RoastLevel = .medium
    @Published var roastDate: Date = Date()
    @Published var beanName: String = ""
    
    func reset() {
        origin = ""
        roastLevel = .medium
        roastDate = Date()
        beanName = ""
    }
    
    func createBean() -> CoffeeBean? {
        guard !beanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        
        return CoffeeBean(
            name: beanName.trimmingCharacters(in: .whitespacesAndNewlines),
            roastLevel: roastLevel,
            origin: origin.trimmingCharacters(in: .whitespacesAndNewlines),
            roastDate: roastDate
        )
    }
}

// MARK: - Shot Creation State
class ShotCreationState: ObservableObject {
    @Published var selectedBean: CoffeeBean?
    @Published var grindSetting: Double = 5.0
    @Published var dose: String = ""
    @Published var shotTime: Double = 0
    @Published var yield: String = ""
    @Published var tasteNotes: String = ""
    @Published var isTimerRunning: Bool = false
    @Published var timer: Timer?
    
    func reset() {
        selectedBean = nil
        grindSetting = 5.0
        dose = ""
        shotTime = 0
        yield = ""
        tasteNotes = ""
        isTimerRunning = false
        stopTimer()
    }
    
    func startTimer() {
        shotTime = 0
        isTimerRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            self.shotTime += 0.1
        }
    }
    
    func stopTimer() {
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    func createShot() -> EspressoShot? {
        guard let bean = selectedBean,
              let doseValue = Double(dose),
              let yieldValue = Double(yield),
              doseValue > 0 else {
            return nil
        }
        
        return EspressoShot(
            date: Date(),
            grindSetting: grindSetting,
            coffeeBean: bean,
            dose: doseValue,
            yield: yieldValue,
            shotTime: shotTime,
            tasteNotes: tasteNotes
        )
    }
}

// MARK: - Individual Page Views

// MARK: - Bean Creation Page Views

// Page 1: Bean Origin
struct BeanOriginView: View {
    @ObservedObject var state: BeanCreationState
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            HeaderView(title: "Bean Origin", step: 1, totalSteps: 4)
            
            VStack(spacing: 20) {
                Text("Where is this coffee from?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
            Image(systemName: "globe")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 15) {
                        TextField("e.g., Ethiopia, Colombia, Brazil", text: $state.origin)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Text("Enter the country or region where this coffee was grown")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            Button(action: onNext) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(state.origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(state.origin.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
    }
}

// Page 2: Roast Level
struct BeanRoastLevelView: View {
    @ObservedObject var state: BeanCreationState
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            HeaderView(title: "Roast Level", step: 2, totalSteps: 4)
            
            VStack(spacing: 20) {
                Text("What roast level is this bean?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 15) {
                    ForEach(RoastLevel.allCases, id: \.self) { level in
                        Button(action: {
                            state.roastLevel = level
                        }) {
                            HStack {
                                Image(systemName: state.roastLevel == level ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(state.roastLevel == level ? .blue : .gray)
                                Text(level.rawValue)
                                    .font(.title2)
                                Spacer()
                                
                                // Visual roast indicator
                                Circle()
                                    .fill(roastLevelColor(level))
                                    .frame(width: 20, height: 20)
                            }
                            .padding()
                            .background(state.roastLevel == level ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            .cornerRadius(12)
                        }
                        .foregroundColor(.primary)
                    }
                }
            }
            
            Spacer()
            
            NavigationButtons(onBack: onBack, onNext: onNext)
        }
        .padding()
    }
    
    private func roastLevelColor(_ level: RoastLevel) -> Color {
        switch level {
        case .light:
            return .orange
        case .medium:
            return .brown
        case .dark:
            return .black
        }
    }
}

// Page 3: Roast Date
struct BeanRoastDateView: View {
    @ObservedObject var state: BeanCreationState
    let onNext: () -> Void
    let onBack: () -> Void
    
    var daysSinceRoast: Int {
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: state.roastDate, to: Date()).day ?? 0
    }
    
    var body: some View {
        VStack(spacing: 30) {
            HeaderView(title: "Roast Date", step: 3, totalSteps: 4)
            
            VStack(spacing: 20) {
                Text("When was this coffee roasted?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    Image(systemName: "calendar")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    VStack(spacing: 15) {
                        DatePicker("Roast Date", selection: $state.roastDate, displayedComponents: .date)
                            .datePickerStyle(WheelDatePickerStyle())
                            .labelsHidden()
                        
                        if daysSinceRoast >= 0 {
                            VStack(spacing: 5) {
                                Text("\(daysSinceRoast) days old")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                                
                                Text(freshnessDescription)
                                    .font(.subheadline)
                                    .foregroundColor(freshnessColor)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        Text("Fresher beans (3-14 days) are ideal for espresso")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            NavigationButtons(onBack: onBack, onNext: onNext)
        }
        .padding()
    }
    
    private var freshnessDescription: String {
        switch daysSinceRoast {
        case 0...3:
            return "Very Fresh"
        case 4...7:
            return "Fresh"
        case 8...14:
            return "Good"
        case 15...21:
            return "Fair"
        default:
            return "Old"
        }
    }
    
    private var freshnessColor: Color {
        switch daysSinceRoast {
        case 0...7:
            return .green
        case 8...14:
            return .orange
        default:
            return .red
        }
    }
}

// Page 4: Bean Name
struct BeanNameView: View {
    @ObservedObject var state: BeanCreationState
    let onFinish: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            HeaderView(title: "Name Your Bean", step: 4, totalSteps: 4)
            
            VStack(spacing: 20) {
                Text("What would you like to call this bean?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    VStack(spacing: 15) {
                        TextField("e.g., Ethiopian Yirgacheffe", text: $state.beanName)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        // Preview of the bean
                        if !state.beanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            VStack(spacing: 8) {
                                Text("Preview:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(state.beanName.trimmingCharacters(in: .whitespacesAndNewlines))
                                        .font(.headline)
                                        .fontWeight(.medium)
                                    
                                    HStack {
                                        Text(state.roastLevel.rawValue)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 2)
                                            .background(roastLevelColor)
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                        
                                        Text(state.origin)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                            }
                        }
                        
                        Text("Choose a name that helps you identify this specific bean")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: onFinish) {
                    Text("Save Bean")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(state.beanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(state.beanName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Button(action: onBack) {
                    Text("Back")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    private var roastLevelColor: Color {
        switch state.roastLevel {
        case .light:
            return .orange
        case .medium:
            return .brown
        case .dark:
            return .black
        }
    }
}

// MARK: - Bean Creation Flow Navigation Controller
struct BeanCreationFlow: View {
    @StateObject private var state = BeanCreationState()
    @ObservedObject var beanManager: BeanManager
    @State private var currentPage = 0
    let onComplete: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Group {
            switch currentPage {
            case 0:
                BeanOriginView(state: state) {
                    currentPage = 1
                }
            case 1:
                BeanRoastLevelView(state: state, onNext: {
                    currentPage = 2
                }, onBack: {
                    currentPage = 0
                })
            case 2:
                BeanRoastDateView(state: state, onNext: {
                    currentPage = 3
                }, onBack: {
                    currentPage = 1
                })
            case 3:
                BeanNameView(state: state, onFinish: {
                    if let bean = state.createBean() {
                        beanManager.addBean(bean)
                        onComplete()
                    }
                }, onBack: {
                    currentPage = 2
                })
            default:
                EmptyView()
            }
        }
        .overlay(
            // Cancel button in top-right corner
            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.gray)
            }
            .padding()
            , alignment: .topTrailing
        )
    }
}

// Page 1: Choose Bean
struct ChooseBeanView: View {
    @ObservedObject var state: ShotCreationState
    @ObservedObject var beanManager: BeanManager
    @State private var showingAddBean = false
    let onNext: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            HeaderView(title: "Choose Bean", step: 1, totalSteps: 6)
            
            VStack(spacing: 20) {
                Text("Which coffee bean are you using?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                if beanManager.beans.isEmpty {
                    VStack(spacing: 15) {
                        Image(systemName: "leaf")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No beans added yet")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Add your first coffee bean to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(beanManager.beans) { bean in
                                BeanRowView(
                                    bean: bean,
                                    isSelected: state.selectedBean?.id == bean.id,
                                    onSelect: {
                                        state.selectedBean = bean
                                    },
                                    onDelete: {
                                        beanManager.deleteBean(bean)
                                        if state.selectedBean?.id == bean.id {
                                            state.selectedBean = nil
                                        }
                                    }
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
                
                Button(action: { showingAddBean = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add New Bean")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
            
            Spacer()
            
            Button(action: onNext) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(state.selectedBean != nil ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(state.selectedBean == nil)
        }
        .padding()
        .fullScreenCover(isPresented: $showingAddBean) {
            BeanCreationFlow(beanManager: beanManager, onComplete: {
                showingAddBean = false
            }, onCancel: {
                showingAddBean = false
            })
        }
    }
}

// Bean Row View
struct BeanRowView: View {
    let bean: CoffeeBean
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(bean.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                HStack {
                    Text(bean.roastLevel.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(roastLevelColor)
                        .foregroundColor(.white)
                        .cornerRadius(4)
                    
                    Text(bean.origin)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text("\(bean.daysSinceRoast) days old")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(bean.freshnessDescription)
                        .font(.caption)
                        .foregroundColor(freshnessColor)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title2)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            onSelect()
        }
    }
    
    private var roastLevelColor: Color {
        switch bean.roastLevel {
        case .light:
            return .orange
        case .medium:
            return .brown
        case .dark:
            return .black
        }
    }
    
    private var freshnessColor: Color {
        switch bean.daysSinceRoast {
        case 0...7:
            return .green
        case 8...14:
            return .orange
        default:
            return .red
        }
    }
}

// Page 2: Grind Setting
struct GrindSettingView: View {
    @ObservedObject var state: ShotCreationState
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            HeaderView(title: "Grind Setting", step: 2, totalSteps: 6)
            
            VStack(spacing: 20) {
                Text("What grind setting did you use?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    Text(String(format: "%.1f", state.grindSetting))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    VStack(spacing: 10) {
                        Text("Grind Setting")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Slider(value: $state.grindSetting, in: 1...10, step: 0.5)
                            .accentColor(.blue)
                        
                        HStack {
                            Text("1.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("10.0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            Spacer()
            
            NavigationButtons(onBack: onBack, onNext: onNext)
        }
        .padding()
    }
}

// Page 3: Dose
struct DoseView: View {
    @ObservedObject var state: ShotCreationState
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            HeaderView(title: "Coffee Dose", step: 3, totalSteps: 6)
            
            VStack(spacing: 20) {
                Text("How much coffee did you use?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    HStack(alignment: .bottom) {
                        TextField("18", text: $state.dose)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        Text("g")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    Text("Typical range: 16-20g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            NavigationButtons(onBack: onBack, onNext: onNext, nextDisabled: state.dose.isEmpty)
        }
        .padding()
    }
}

// Page 4: Shot Timer
struct ShotTimerView: View {
    @ObservedObject var state: ShotCreationState
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            HeaderView(title: "Shot Timer", step: 4, totalSteps: 6)
            
            VStack(spacing: 20) {
                Text("Time your espresso shot")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 30) {
                    Text(String(format: "%.1f", state.shotTime))
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(state.isTimerRunning ? .green : .blue)
                    
                    Text("seconds")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        if state.isTimerRunning {
                            state.stopTimer()
                        } else {
                            state.startTimer()
                        }
                    }) {
                        Text(state.isTimerRunning ? "Stop" : "Start")
                            .font(.title)
                            .frame(width: 120, height: 120)
                            .background(state.isTimerRunning ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    
                    if state.shotTime > 0 && !state.isTimerRunning {
                        Text("Typical range: 25-35 seconds")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            NavigationButtons(onBack: onBack, onNext: onNext, nextDisabled: state.shotTime == 0)
        }
        .padding()
    }
}

// Page 5: Yield
struct YieldView: View {
    @ObservedObject var state: ShotCreationState
    let onNext: () -> Void
    let onBack: () -> Void
    
    var extractionRatio: Double? {
        guard let doseValue = Double(state.dose),
              let yieldValue = Double(state.yield),
              doseValue > 0 else {
            return nil
        }
        return yieldValue / doseValue
    }
    
    var body: some View {
        VStack(spacing: 30) {
            HeaderView(title: "Shot Yield", step: 5, totalSteps: 6)
            
            VStack(spacing: 20) {
                Text("How much espresso did you get?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 20) {
                    HStack(alignment: .bottom) {
                        TextField("36", text: $state.yield)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.center)
                            .textFieldStyle(PlainTextFieldStyle())
                        
                        Text("g")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    if let ratio = extractionRatio {
                        VStack(spacing: 5) {
                            Text("Extraction Ratio")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f", ratio))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Text("Typical range: 30-40g")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            NavigationButtons(onBack: onBack, onNext: onNext, nextDisabled: state.yield.isEmpty)
        }
        .padding()
    }
}

// Page 6: Taste Notes
struct TasteNotesView: View {
    @ObservedObject var state: ShotCreationState
    let onFinish: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            HeaderView(title: "Taste Notes", step: 6, totalSteps: 6)
            
            VStack(spacing: 20) {
                Text("How did your shot taste?")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 15) {
                    TextField("Describe the taste, aroma, and overall experience...", text: $state.tasteNotes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(5...10)
                        .frame(minHeight: 120)
                    
                    Text("Optional: Add notes about sweetness, acidity, body, or any flavors you noticed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            
            Spacer()
            
            VStack(spacing: 15) {
                Button(action: onFinish) {
                    Text("Save Shot")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button(action: onBack) {
                    Text("Back")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
    }
}

// MARK: - Helper Views

struct HeaderView: View {
    let title: String
    let step: Int
    let totalSteps: Int
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 30))
                .foregroundColor(.brown)
            
            Text("Espresso Trainer")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.blue)
            
            ProgressView(value: Double(step), total: Double(totalSteps))
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 8)
            
            Text("Step \(step) of \(totalSteps)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct NavigationButtons: View {
    let onBack: () -> Void
    let onNext: () -> Void
    var nextDisabled: Bool = false
    
    var body: some View {
        HStack(spacing: 15) {
            Button(action: onBack) {
                Text("Back")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: onNext) {
                Text("Next")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(nextDisabled ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(nextDisabled)
        }
    }
}

// MARK: - Main Navigation Controller
struct ShotCreationFlow: View {
    @StateObject private var state = ShotCreationState()
    @StateObject private var beanManager = BeanManager()
    @State private var currentPage = 0
    let onComplete: (EspressoShot) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        Group {
            switch currentPage {
            case 0:
                ChooseBeanView(state: state, beanManager: beanManager) {
                    currentPage = 1
                }
            case 1:
                GrindSettingView(state: state, onNext: {
                    currentPage = 2
                }, onBack: {
                    currentPage = 0
                })
            case 2:
                DoseView(state: state, onNext: {
                    currentPage = 3
                }, onBack: {
                    currentPage = 1
                })
            case 3:
                ShotTimerView(state: state, onNext: {
                    currentPage = 4
                }, onBack: {
                    currentPage = 2
                })
            case 4:
                YieldView(state: state, onNext: {
                    currentPage = 5
                }, onBack: {
                    currentPage = 3
                })
            case 5:
                TasteNotesView(state: state, onFinish: {
                    if let shot = state.createShot() {
                        onComplete(shot)
                    }
                }, onBack: {
                    currentPage = 4
                })
            default:
                EmptyView()
            }
        }
        .onDisappear {
            state.stopTimer()
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var shots: [EspressoShot] = []
    @State private var showingShotCreation = false
    @State private var showingPastShots = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.brown)
                    
                    Text("Espresso Trainer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Track your perfect shot")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Action Buttons
                VStack(spacing: 15) {
                    Button(action: { showingShotCreation = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("New Shot")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button(action: { showingPastShots = true }) {
                        HStack {
                            Image(systemName: "clock.fill")
                                .font(.title2)
                            Text("View History")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Recent Shots
                if !shots.isEmpty {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Recent Shots")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(shots.prefix(3)) { shot in
                                    ShotRowView(shot: shot)
                                }
                            }
                        }
                    }
                } else {
                    VStack(spacing: 10) {
                        Image(systemName: "mug")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        
                        Text("No shots recorded yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Tap 'New Shot' to get started!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingShotCreation) {
            ShotCreationFlow(
                onComplete: { shot in
                    shots.insert(shot, at: 0)
                    saveShots()
                    showingShotCreation = false
                },
                onCancel: {
                    showingShotCreation = false
                }
            )
        }
        .sheet(isPresented: $showingPastShots) {
            PastShotsView(shots: shots)
        }
        .onAppear {
            loadShots()
        }
    }
    
    // MARK: - Functions
    private func saveShots() {
        if let encoded = try? JSONEncoder().encode(shots) {
            UserDefaults.standard.set(encoded, forKey: "espressoShots")
        }
    }
    
    private func loadShots() {
        if let data = UserDefaults.standard.data(forKey: "espressoShots"),
           let decoded = try? JSONDecoder().decode([EspressoShot].self, from: data) {
            shots = decoded
        }
    }
}

// MARK: - Shot Row View
struct ShotRowView: View {
    let shot: EspressoShot
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(shot.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(shot.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text(shot.coffeeBean.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    Text("Ratio: \(String(format: "%.2f", shot.extractionRatio))")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Bean: \(shot.coffeeBean.name)")
                        .font(.caption)
                        .lineLimit(1)
                    
                    HStack {
                        Text(shot.coffeeBean.roastLevel.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(roastLevelColor)
                            .foregroundColor(.white)
                            .cornerRadius(3)
                        
                        Text(shot.coffeeBean.origin)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("Dose: \(String(format: "%.1fg", shot.dose))")
                        .font(.caption)
                    Text("Yield: \(String(format: "%.1fg", shot.yield))")
                        .font(.caption)
                }
            }
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Time: \(String(format: "%.0fs", shot.shotTime))")
                        .font(.caption)
                    Text("Grind: \(String(format: "%.1f", shot.grindSetting))")
                        .font(.caption)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(shot.coffeeBean.daysSinceRoast) days old")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(shot.coffeeBean.freshnessDescription)
                        .font(.caption)
                        .foregroundColor(freshnessColor)
                }
            }
            
            if !shot.tasteNotes.isEmpty {
                Text(shot.tasteNotes)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal)
    }
    
    private var roastLevelColor: Color {
        switch shot.coffeeBean.roastLevel {
        case .light:
            return .orange
        case .medium:
            return .brown
        case .dark:
            return .black
        }
    }
    
    private var freshnessColor: Color {
        switch shot.coffeeBean.daysSinceRoast {
        case 0...7:
            return .green
        case 8...14:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Past Shots View
struct PastShotsView: View {
    let shots: [EspressoShot]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(shots) { shot in
                ShotRowView(shot: shot)
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Shot History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
