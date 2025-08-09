import SwiftUI
import AVFoundation

struct BatteryScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var batteryManager: BatteryManager
    @StateObject private var cameraManager = CameraManager()
    @State private var showingManualEntry = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.voltLoopBlack
                    .ignoresSafeArea()
                
                VStack {
                    // Camera Preview
                    if cameraManager.isAuthorized {
                        CameraPreviewView(cameraManager: cameraManager)
                            .overlay(
                                // Scanning Reticle
                                ZStack {
                                    // Corner brackets
                                    VStack {
                                        HStack {
                                            CornerBracket(position: .topLeft)
                                            Spacer()
                                            CornerBracket(position: .topRight)
                                        }
                                        Spacer()
                                        HStack {
                                            CornerBracket(position: .bottomLeft)
                                            Spacer()
                                            CornerBracket(position: .bottomRight)
                                        }
                                    }
                                    .padding(60)
                                    
                                    // Center text
                                    VStack {
                                        Spacer()
                                        Text("Position barcode within frame")
                                            .font(.system(size: 16, weight: .medium, design: .default))
                                            .foregroundColor(.voltLoopWhite)
                                            .padding(.bottom, 100)
                                    }
                                }
                            )
                    } else {
                        // Camera not authorized
                        VStack(spacing: 20) {
                            Image(systemName: "camera.slash.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.voltLoopOrange)
                            
                            Text("Camera Access Required")
                                .font(.system(size: 24, weight: .bold, design: .default))
                                .foregroundColor(.primaryText)
                            
                            Text("Please enable camera access in Settings to scan barcodes")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button("Open Settings") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .voltLoopButtonStyle()
                            .padding(.horizontal, 40)
                        }
                    }
                    
                    // Bottom Controls
                    VStack(spacing: 16) {
                        if cameraManager.isScanning {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .voltLoopBlue))
                                    .scaleEffect(0.8)
                                
                                Text("Scanning...")
                                    .font(.system(size: 16, weight: .medium, design: .default))
                                    .foregroundColor(.voltLoopBlue)
                            }
                        }
                        
                        HStack(spacing: 20) {
                            Button("Manual Entry") {
                                showingManualEntry = true
                            }
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.voltLoopBlue)
                            
                            Spacer()
                            
                            Button("Cancel") {
                                dismiss()
                            }
                            .font(.system(size: 16, weight: .medium, design: .default))
                            .foregroundColor(.voltLoopWhite)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Scan Battery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.voltLoopBlue)
                }
            }
        }
        .onAppear {
            cameraManager.requestLocationPermission()
        }
        .onChange(of: cameraManager.scannedCode) { code in
            if let code = code {
                Task {
                    await batteryManager.scanBattery()
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualBatteryEntryView()
        }
        .alert("Scan Error", isPresented: .constant(cameraManager.error != nil)) {
            Button("OK") {
                cameraManager.error = nil
            }
        } message: {
            Text(cameraManager.error ?? "")
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let cameraManager: CameraManager
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        
        if let previewLayer = cameraManager.getPreviewLayer() {
            previewLayer.frame = view.bounds
            view.layer.addSublayer(previewLayer)
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if let previewLayer = cameraManager.getPreviewLayer() {
            previewLayer.frame = uiView.bounds
        }
    }
}

struct CornerBracket: View {
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    let position: Position
    
    var body: some View {
        ZStack {
            // Horizontal line
            Rectangle()
                .fill(Color.voltLoopBlue)
                .frame(width: 30, height: 3)
                .rotationEffect(.degrees(rotationAngle))
            
            // Vertical line
            Rectangle()
                .fill(Color.voltLoopBlue)
                .frame(width: 3, height: 30)
                .rotationEffect(.degrees(rotationAngle))
        }
        .voltLoopGlow(color: .voltLoopBlue, radius: 5)
    }
    
    private var rotationAngle: Double {
        switch position {
        case .topLeft:
            return 0
        case .topRight:
            return 90
        case .bottomRight:
            return 180
        case .bottomLeft:
            return 270
        }
    }
}

struct ManualBatteryEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var batteryManager: BatteryManager
    @State private var selectedType: BatteryType = .alkaline
    @State private var model = ""
    @State private var manufacturer = ""
    @State private var capacity = ""
    @State private var voltage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "keyboard")
                                .font(.system(size: 60))
                                .foregroundColor(.voltLoopBlue)
                                .voltLoopGlow(color: .voltLoopBlue, radius: 20)
                            
                            Text("Manual Entry")
                                .font(.system(size: 28, weight: .bold, design: .default))
                                .foregroundColor(.primaryText)
                            
                            Text("Enter battery information manually")
                                .font(.system(size: 16, weight: .medium, design: .default))
                                .foregroundColor(.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 20)
                        
                        // Form
                        VStack(spacing: 20) {
                            // Battery Type
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Battery Type")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(.primaryText)
                                
                                Picker("Battery Type", selection: $selectedType) {
                                    ForEach(BatteryType.allCases, id: \.self) { type in
                                        HStack {
                                            Image(systemName: type.icon)
                                            Text(type.rawValue)
                                        }
                                        .tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.secondaryBorder, lineWidth: 1)
                                )
                            }
                            
                            // Model
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Model")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(.primaryText)
                                
                                TextField("e.g., DURACELL_AA", text: $model)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Manufacturer
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Manufacturer")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(.primaryText)
                                
                                TextField("e.g., Duracell", text: $manufacturer)
                                    .textFieldStyle(CustomTextFieldStyle())
                            }
                            
                            // Capacity
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Capacity (mAh)")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(.primaryText)
                                
                                TextField("e.g., 2500", text: $capacity)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.numberPad)
                            }
                            
                            // Voltage
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Voltage (V)")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                                    .foregroundColor(.primaryText)
                                
                                TextField("e.g., 1.5", text: $voltage)
                                    .textFieldStyle(CustomTextFieldStyle())
                                    .keyboardType(.decimalPad)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        // Submit Button
                        Button(action: {
                            Task {
                                await submitManualEntry()
                            }
                        }) {
                            HStack {
                                if batteryManager.isScanning {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .voltLoopBlack))
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 20))
                                }
                                
                                Text("Submit")
                                    .font(.system(size: 16, weight: .semibold, design: .default))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                        .voltLoopButtonStyle(isPrimary: false)
                        .disabled(batteryManager.isScanning || model.isEmpty || manufacturer.isEmpty)
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Manual Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.voltLoopBlue)
                }
            }
        }
        .alert("Error", isPresented: .constant(batteryManager.scanError != nil)) {
            Button("OK") {
                batteryManager.scanError = nil
            }
        } message: {
            Text(batteryManager.scanError ?? "")
        }
    }
    
    private func submitManualEntry() async {
        let battery = Battery(
            model: model,
            type: selectedType,
            manufacturer: manufacturer,
            capacity: Double(capacity),
            voltage: Double(voltage),
            age: nil,
            chargeCycles: nil,
            barcode: nil
        )
        
        await batteryManager.scanBatteryManually(model: model, type: selectedType)
        dismiss()
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondaryBorder, lineWidth: 1)
            )
            .foregroundColor(.primaryText)
    }
}

struct BatteryScannerView_Previews: PreviewProvider {
    static var previews: some View {
        BatteryScannerView()
            .environmentObject(BatteryManager())
    }
} 