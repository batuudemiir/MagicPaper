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

    /// Okuyucuda "Konuşalım" (Faz 11): sayfa dizini → soru. Kısa masalda iki,
    /// uzunda üç sayfa; ilk ve son sayfada hiç. Soru türleri sayfanın yerine
    /// göre değişir (Strouse ve Troseth 2023; PEER, CROWD): başta tahmin,
    /// ortada duygu ve neden, sonda çocuğun kendi hayatı. Masallar bugün
    /// resimsiz, bu yüzden "resimde ne görüyorsun" sorusu yok.
    static func pagePrompts(for story: Story) -> [Int: String] {
        let count = story.pages.count
        guard count >= 4 else { return [:] }
        let name = story.childName
        let young = story.origin?.ageBand.map { $0.hasPrefix("3") } ?? false
        let fractions = count >= 7 ? [0.3, 0.55, 0.8] : [0.35, 0.7]
        let pools = young ? youngPagePools(name: name) : pagePools(name: name)
        let key = story.id.uuidString.utf8.reduce(0) { ($0 &* 31 &+ Int($1)) & 0xFFFF }
        var result: [Int: String] = [:]
        for (slot, fraction) in fractions.enumerated() {
            let index = min(max(Int(Double(count) * fraction), 1), count - 2)
            guard result[index] == nil else { continue }
            let pool = pools[min(slot * pools.count / fractions.count, pools.count - 1)]
            result[index] = pool[(key + slot) % pool.count]
        }
        return result
    }

    private static func pagePools(name: String) -> [[String]] {
        [
            ["Sence şimdi ne olacak?", "Sence bu ne olabilir?", "\(name) şimdi ne yapmalı sence?"],
            ["\(name) şu an nasıl hissediyor sence?", "Sence neden böyle oldu?",
             "Sen olsan şimdi ne yapardın?"],
            ["Sen hiç böyle bir şey yaşadın mı?", "Sence masal nasıl bitecek?",
             "Bu sana neyi hatırlattı?"]
        ]
    }

    private static func youngPagePools(name: String) -> [[String]] {
        [
            ["Sence şimdi ne olacak?", "Bu ne olabilir sence?"],
            ["\(name) nasıl hissediyor?", "Sen de böyle yapar mısın?"],
            ["Sence masal nasıl bitecek?", "Sen olsan ne yapardın?"]
        ]
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
