#if DEBUG
import SwiftUI

struct MPCatalogControlExamples: View {
    let onAction: (String) -> Void
    @State private var selectedChip = true
    @State private var dashedChip = false
    @State private var segment = false
    @State private var switchOn = false
    @State private var checked = false
    @State private var plainText = ""
    @State private var helperText = "Örnek metin"
    @State private var errorText = "Uzun bir metin alanı örneğini burada inceleyebilirsin"

    var body: some View {
        VStack(alignment: .leading, spacing: MP.S.x6) {
            chips
            choices
            fields
        }
        .onChange(of: segment) { _, value in onAction(value ? "İkinci segment" : "İlk segment") }
        .onChange(of: switchOn) { _, value in onAction(value ? "Anahtar açık" : "Anahtar kapalı") }
        .onChange(of: checked) { _, value in onAction(value ? "Onay kutusu seçili" : "Onay kutusu seçili değil") }
    }

    private var chips: some View {
        MPCatalogSample(title: "MPChip", note: "solid seçili / seçili değil / dashed. Dokunarak seçimi değiştir.") {
            VStack(alignment: .leading, spacing: MP.S.x3) {
                MPChip(title: "Birinci seçenek", isSelected: selectedChip) {
                    selectedChip.toggle()
                    onAction("Birinci çip seçimi değişti")
                }
                MPChip(title: "İkinci seçenek", isSelected: !selectedChip, height: MPSize.chipHeightKid) {
                    selectedChip.toggle()
                    onAction("İkinci çip seçimi değişti")
                }
                MPChip(title: "Kesik çizgili seçenek", isSelected: dashedChip, style: .dashed) {
                    dashedChip.toggle()
                    onAction("Kesik çizgili çip seçimi değişti")
                }
            }
        }
    }

    private var choices: some View {
        MPCatalogSample(title: "Seçim kontrolleri", note: "MPSegmented / MPSwitchStyle / MPCheckbox. Yalnız geçici seçimlerdir.") {
            VStack(alignment: .leading, spacing: MP.S.x4) {
                MPSegmented(options: [(false, "Birinci"), (true, "İkinci")], selection: $segment)
                Toggle("Örnek anahtar", isOn: $switchOn)
                    .mpText(.body).toggleStyle(MPSwitchStyle())
                MPCheckbox(isOn: $checked, label: "Örnek onay kutusu; gerçek bir izin kaydı tutulmaz.")
            }
        }
    }

    private var fields: some View {
        MPCatalogSample(title: "MPTextField", note: "Normal / yardımcı metin / hata ve uzun içerik. Yazılan metin kaydedilmez.") {
            VStack(alignment: .leading, spacing: MP.S.x4) {
                MPTextField(label: "Normal alan", placeholder: "Örnek yazı", text: $plainText)
                MPTextField(label: "Yardımcı metinli alan", placeholder: "Örnek yazı", text: $helperText,
                            helper: "Bu metin yalnız katalogda görünür.")
                MPTextField(label: "Hata durumu", placeholder: "Örnek yazı", text: $errorText,
                            helper: "Hata mesajı örneği: alanı yeniden kontrol et.", isError: true)
            }
        }
    }
}
#endif
