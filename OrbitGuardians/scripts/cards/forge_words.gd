extends RefCounted
class_name AstraForgeWords
const TEXT={
 "forge_deck":["Боевой набор","Command deck","Einsatzdeck"],
 "deck_edit_tip":["3–6 чертежей · хотя бы один атакующий робот. Награды остаются в запасе.","3–6 blueprints · at least one attacker. Rewards stay in reserve.","3–6 Baupläne · mindestens ein Angreifer. Belohnungen bleiben in Reserve."],
 "next_battle":["Изменения — со следующего боя","Changes apply next battle","Änderungen ab nächstem Kampf"],
 "loadout_saved":["Боевой набор сохранён","Command deck saved","Einsatzdeck gespeichert"],
 "loadout_apply":["Сохранить набор","Save loadout","Deck speichern"],
 "equipped":["В наборе","Equipped","Ausgerüstet"],
 "reserve":["Запас","Reserve","Reserve"],
 "supplies":["Снабжение","Supplies","Versorgung"],
 "supply_tip":["Покупки за сплав. Расходники применяются сразу и не требуют энергии.","Buy with alloy. Items act immediately and cost no energy.","Mit Legierung kaufen. Gegenstände wirken sofort ohne Energie."],
 "supply_items":["Расходники","Items","Gegenstände"],
 "blueprints":["Чертежи","Blueprints","Baupläne"],
 "medkit":["Наноремонт","Nano repair","Nanoreparatur"],
 "battery":["Энергоячейка","Energy cell","Energiezelle"],
 "purge":["Очиститель","Cleanser","Reiniger"],
 "bomb":["Ударный дрон","Strike drone","Angriffsdrohne"],
 "quick_medkit":["Ремонт","Repair","Reparatur"],
 "quick_battery":["Энергия","Energy","Energie"],
 "quick_purge":["Очистка","Cleanse","Reinigen"],
 "quick_bomb":["Удар","Strike","Angriff"],
 "medkit_tip":["Ядру +8 HP","Core +8 HP","Kern +8 LP"],
 "battery_tip":["+2 энергии","+2 energy","+2 Energie"],
 "purge_tip":["Снимает холод, поджог и глушение","Removes chill, burn and jam","Entfernt Kälte, Brand und Störung"],
 "bomb_tip":["Всем врагам 2 урона","2 damage to every enemy","2 Schaden an alle Gegner"],
 "apply":["Применить","Use","Anwenden"],
 "purchase":["Купить","Buy","Kaufen"],
 "used_command":["Следующий ход","Next turn","Nächster Zug"],
 "target_hint":["Робот → цель","Robot → target","Roboter → Ziel"],
 "withdraw":["Разобрать","Dismantle","Zerlegen"],
 "plan":["Ваш ход","Your turn","Dein Zug"],
 "resolution":["Атаки","Attacks","Angriffe"],
 "foe":["Противник","Enemy","Gegner"],
 "you":["Вы","You","Du"],
 "prepared":["Каждый чертёж — раз за ход","Each blueprint: once per turn","Jeder Bauplan: einmal pro Zug"],
 "freeze_fair":["Холод: −1 атака, не пропуск хода","Chill: −1 attack, no skipped turn","Kälte: −1 Angriff, kein Zugausfall"]
}
static func get_text(key: String, language: String) -> String:
 return AstraCards.word(TEXT[key],language) if TEXT.has(key) else AstraDesktopWords.get_text(key,language)

static func description(entry: Dictionary, language: String) -> String:
 var display=entry.duplicate(true)
 if display.effect=="freeze":display.effect="chill"
 if display.effect=="frost":display.effect="softfrost"
 if display.effect=="recall":return AstraCards.word(["Разбирает робота; возвращает половину стоимости","Dismantles a robot; refunds half its cost","Zerlegt einen Roboter; erstattet die halben Kosten"],language)
 if display.effect=="echo":return AstraCards.word(["Квантовый штурмовик Астры","Astra's quantum assault unit","Astras Quanten-Sturmeinheit"],language)
 return AstraCards.description(display,language)
