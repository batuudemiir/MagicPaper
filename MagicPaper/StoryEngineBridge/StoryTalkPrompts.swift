import Foundation

/// Masal sonu "Birlikte konuşalım" (Faz 4): ebeveyn ve çocuğu konuşturan iki açık soru.
///
/// Sınav değil: doğru cevabı yok, puanlanmaz, kaydedilmez. Sorular diyalojik okumanın
/// hatırlatma, açık uçlu ve kendi hayatıyla bağ türlerinden. Aynı masalda hep aynı
/// sorular çıkar; serbest metin yazılmaz.
enum StoryTalkPrompts {

    static func questions(for story: Story) -> [String] {
        let name = story.childName
        let young = story.origin?.ageBand.map { $0.hasPrefix("3") } ?? false
        let pool = young ? youngPool(name: name) : pool(for: story.origin?.mode, name: name)
        guard pool.count >= 2 else { return pool }
        // `hashValue` her açılışta değişir; masalın kimliğinden sabit bir sıra.
        let key = story.id.uuidString.utf8.reduce(0) { ($0 &* 31 &+ Int($1)) & 0xFFFF }
        let first = key % pool.count
        let second = (first + 1 + key % (pool.count - 1)) % pool.count
        return [pool[first], pool[second]]
    }

    private static func youngPool(name: String) -> [String] {
        [
            "Masalda en çok neyi sevdin?",
            "Sence \(name) masalın sonunda nasıl hissetti?",
            "Masaldan bir şeyi bize canlandırır mısın?",
            "Masalda sana en komik gelen ne oldu?"
        ]
    }

    private static func pool(for mode: StoryMode?, name: String) -> [String] {
        let common = [
            "Masalda en çok hangi an aklında kaldı?",
            "Sen olsan masalın sonunu nasıl değiştirirdin?"
        ]
        switch mode {
        case .adventure:
            return common + [
                "Sen bu yolculukta olsan yanına ne alırdın?",
                "Masaldaki en zor anda sen ne yapardın?",
                "Bir sonraki macera nereye gitsin?"
            ]
        case .learning:
            return common + [
                "Bu masalda yeni ne öğrendin?",
                "Masaldan öğrendiğini bugün nerede görebilirsin?",
                "Bunu en çok kime anlatmak isterdin?"
            ]
        default:
            return common + [
                "Sen olsan masalda ne yapardın?",
                "Masal sana kendi hayatından neyi hatırlattı?",
                "\(name) yarın ne yapmak ister sence?"
            ]
        }
    }
}
