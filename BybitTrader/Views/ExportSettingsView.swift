import SwiftUI

struct ExportSettingsView: View {
    let settings: String
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Иконка
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                // Заголовок
                VStack(spacing: 8) {
                    Text("Экспорт настроек")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Ваши настройки готовы к экспорту")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Предварительный просмотр
                VStack(alignment: .leading, spacing: 8) {
                    Text("Предварительный просмотр:")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    ScrollView {
                        Text(settings)
                            .font(.caption)
                            .fontFamily(.monospaced)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
                
                // Кнопки действий
                VStack(spacing: 12) {
                    Button(action: {
                        showingShareSheet = true
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Поделиться")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                    }
                    
                    Button(action: {
                        UIPasteboard.general.string = settings
                    }) {
                        HStack {
                            Image(systemName: "doc.on.doc")
                            Text("Копировать в буфер")
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(25)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Экспорт")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Готово") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [settings])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportSettingsView(settings: "Пример настроек...")
}
