import Foundation

/// Bakchod desi toast messages — random pick on each action
struct DesiMessages {
    
    // MARK: - On Saving Expense
    
    static func onExpenseSaved(amount: Double, language: AppLanguage) -> String {
        let messages: [AppLanguage: [String]] = [
            .hinglish: [
                "Ek aur kharcha... baap ko mat batana 💀",
                "₹\(Int(amount)) gaye paani mein 💸",
                "Budget bola: 'Main toh gaya' 😭",
                "Bhai sahab, ₹\(Int(amount)) ki dukaan!",
                "Paisa hi paisa hoga... wait, nahi hoga 😅",
                "Ye toh bas trailer tha, poora budget aayega 🎬",
                "₹\(Int(amount))... chal theek hai, note kar liya 📝",
                "ATM mein paisa hai ki nahi check kar le 😬",
                "Mummy ko pata chala toh... 🫣",
                "Aur kharch kar, baap ki dukaan hai kya? 💀"
            ],
            .english: [
                "Another one bites the dust 💸",
                "₹\(Int(amount)) spent. Budget is crying 😭",
                "Noted! Your wallet felt that one 👛",
                "₹\(Int(amount)) gone. Easy come, easy go 🤷",
                "Expense logged! Keep tracking 📝"
            ],
            .hindi: [
                "एक और खर्चा... बाप को मत बताना 💀",
                "₹\(Int(amount)) गए पानी में 💸",
                "बजट बोला: 'मैं तो गया' 😭",
                "भाई साहब, ₹\(Int(amount)) की दुकान!",
                "पैसा ही पैसा होगा... रुको, नहीं होगा 😅"
            ]
        ]
        
        let pool = messages[language] ?? messages[.hinglish]!
        return pool.randomElement()!
    }
    
    // MARK: - Budget Exceeded
    
    static func onBudgetExceeded(daysLeft: Int, language: AppLanguage) -> String {
        let messages: [AppLanguage: [String]] = [
            .hinglish: [
                "Bhai ruk ja! Mahine ke \(daysLeft) din baaki hain 🛑",
                "Tera budget ne resignation de diya hai 📝",
                "Budget phat gaya! Ab kya karega? 😰",
                "Alert: Paisa khatam, mood kharab 🚨",
                "Bhai budget cross ho gaya, thoda control kar 🙏"
            ],
            .english: [
                "Budget exceeded! \(daysLeft) days left this month 🛑",
                "Your budget just resigned 📝",
                "Over budget! Time to cut back 😰"
            ],
            .hindi: [
                "भाई रुक जा! महीने के \(daysLeft) दिन बाकी हैं 🛑",
                "तेरे बजट ने इस्तीफा दे दिया है 📝",
                "बजट फट गया! अब क्या करेगा? 😰"
            ]
        ]
        
        let pool = messages[language] ?? messages[.hinglish]!
        return pool.randomElement()!
    }
    
    // MARK: - Good Savings
    
    static func onGoodSavings(language: AppLanguage) -> String {
        let messages: [AppLanguage: [String]] = [
            .hinglish: [
                "Shabaash! Aaj kuch nahi kharch kiya 🎉",
                "Mummy proud hogi tujhpe 🥹",
                "Budget surplus! Party de de bhai! 🍕",
                "Ye hui na baat! Paisa bach raha hai 💰",
                "Warren Buffett bhi impress hoga 📈"
            ],
            .english: [
                "Great job! Savings looking good 🎉",
                "Your budget is happy today 💰",
                "Under budget! Keep it up! 📈"
            ],
            .hindi: [
                "शाबाश! आज कुछ नहीं खर्च किया 🎉",
                "मम्मी प्राउड होगी तुझपे 🥹",
                "बजट सरप्लस! पार्टी दे दे भाई! 🍕"
            ]
        ]
        
        let pool = messages[language] ?? messages[.hinglish]!
        return pool.randomElement()!
    }
    
    // MARK: - Budget Status Messages
    
    static func budgetStatus(percentage: Double, language: AppLanguage) -> String {
        switch percentage {
        case 0..<25:
            let msgs: [AppLanguage: [String]] = [
                .hinglish: ["Abhi toh shuru bhi nahi hua!", "Mahina naya hai, josh naya hai! 🔥"],
                .english: ["Just getting started!", "New month, fresh budget! 🔥"],
                .hindi: ["अभी तो शुरू भी नहीं हुआ!", "महीना नया है, जोश नया है! 🔥"]
            ]
            return (msgs[language] ?? msgs[.hinglish]!).randomElement()!
            
        case 25..<50:
            let msgs: [AppLanguage: [String]] = [
                .hinglish: ["Chal raha hai, chal raha hai 👍", "Abhi toh party shuru hui hai!"],
                .english: ["Going well so far 👍", "Steady spending!"],
                .hindi: ["चल रहा है, चल रहा है 👍", "अभी तो पार्टी शुरू हुई है!"]
            ]
            return (msgs[language] ?? msgs[.hinglish]!).randomElement()!
            
        case 50..<75:
            let msgs: [AppLanguage: [String]] = [
                .hinglish: ["Aadha budget khatam, thoda sambhal ke 🤔", "Speed breaker lagao bhai 🛑"],
                .english: ["Half the budget gone, be careful 🤔", "Slow down a bit! 🛑"],
                .hindi: ["आधा बजट ख़त्म, थोड़ा संभल के 🤔", "स्पीड ब्रेकर लगाओ भाई 🛑"]
            ]
            return (msgs[language] ?? msgs[.hinglish]!).randomElement()!
            
        case 75..<100:
            let msgs: [AppLanguage: [String]] = [
                .hinglish: ["Budget ro raha hai 😭", "Bhai ab Maggi khana padega baaki mahina 🍜"],
                .english: ["Budget is crying 😭", "Almost maxed out!"],
                .hindi: ["बजट रो रहा है 😭", "भाई अब मैगी खाना पड़ेगा बाकी महीना 🍜"]
            ]
            return (msgs[language] ?? msgs[.hinglish]!).randomElement()!
            
        default:
            let msgs: [AppLanguage: [String]] = [
                .hinglish: ["Budget PHAT gaya! 💥", "Game over bhai, budget khatam 🎮"],
                .english: ["Budget BUSTED! 💥", "Over budget! 🎮"],
                .hindi: ["बजट फट गया! 💥", "गेम ओवर भाई, बजट ख़त्म 🎮"]
            ]
            return (msgs[language] ?? msgs[.hinglish]!).randomElement()!
        }
    }
    
    // MARK: - On Expense Deleted
    
    static func onExpenseDeleted(language: AppLanguage) -> String {
        let messages: [AppLanguage: [String]] = [
            .hinglish: ["Kharcha hata diya, jaise hua hi nahi 🫥", "Delete! Budget thoda khush hua 😊"],
            .english: ["Expense removed 🗑️", "Deleted! Budget is happy 😊"],
            .hindi: ["खर्चा हटा दिया, जैसे हुआ ही नहीं 🫥", "डिलीट! बजट थोड़ा खुश हुआ 😊"]
        ]
        
        let pool = messages[language] ?? messages[.hinglish]!
        return pool.randomElement()!
    }
    
    // MARK: - Fitness Messages
    
    static func fitnessMotivation(steps: Int, goal: Int, language: AppLanguage) -> String {
        let percentage = Double(steps) / Double(goal) * 100
        
        if percentage >= 100 {
            let msgs: [AppLanguage: [String]] = [
                .hinglish: ["Goal complete! Tu toh athlete nikla 🏆", "Bhai maza aa gaya! Target done! 🔥"],
                .english: ["Goal complete! You're a champ 🏆", "Target achieved! 🔥"],
                .hindi: ["गोल पूरा! तू तो एथलीट निकला 🏆", "भाई मज़ा आ गया! टार्गेट डन! 🔥"]
            ]
            return (msgs[language] ?? msgs[.hinglish]!).randomElement()!
        } else if percentage >= 50 {
            let msgs: [AppLanguage: [String]] = [
                .hinglish: ["Aadha ho gaya! Thoda aur chal 🚶", "Body ban rahi hai bhai 💪"],
                .english: ["Halfway there! Keep going 🚶", "Getting fit! 💪"],
                .hindi: ["आधा हो गया! थोड़ा और चल 🚶", "बॉडी बन रही है भाई 💪"]
            ]
            return (msgs[language] ?? msgs[.hinglish]!).randomElement()!
        } else {
            let msgs: [AppLanguage: [String]] = [
                .hinglish: ["Uth bhai, thoda chal! 🛋️", "Body banani hai ya nahi? 🤔"],
                .english: ["Get moving! 🛋️", "Time for a walk! 🤔"],
                .hindi: ["उठ भाई, थोड़ा चल! 🛋️", "बॉडी बनानी है या नहीं? 🤔"]
            ]
            return (msgs[language] ?? msgs[.hinglish]!).randomElement()!
        }
    }
}
