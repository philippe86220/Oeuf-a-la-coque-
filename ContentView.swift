import SwiftUI

// -------------------------------------------------------------
//  Programme SwiftUI : Calcul du temps de cuisson d'un œuf à la coque
// -------------------------------------------------------------
//  Modèle physique : transfert de chaleur dans une sphère homogène
//  Approche simplifiée : température au centre T(0,t)
//  T(0,t) ≈ T₀ + (Tₛ − T₀) * (1 − exp(−λ₁² * α * t / R²))
//  On isole t :
//     t = (R² / (λ₁² * α)) * ln( (Tₛ − T₀) / (Tₛ − T_c) )
// -------------------------------------------------------------
//  Auteur : Philippe  & ChatGPT
//  Langage : SwiftUI
// -------------------------------------------------------------


// -------------------------------------------------------------
//  Calcul du temps de cuisson d'un œuf à la coque – avec AIDE intégrée
//  Modèle : T(0,t) = T0 + (Ts − T0) * (1 − exp(−λ1² * α * t / R²))
//  Temps :  t = (R² / (λ1² * α)) * ln((Ts − T0) / (Ts − Tc))
//  λ1 ≈ π pour une sphère (mode fondamental)
// -------------------------------------------------------------

struct ContentView: View {

    // --- Paramètres physiques (saisies utilisateur) ---
    @State private var rayon: String = "0.02"                  // m
    @State private var temperatureSurface: String = "98"       // °C
    @State private var temperatureInitiale: String = "20"      // °C
    @State private var temperatureCible: String = "65"         // °C
    @State private var diffusiviteThermique: String = "1.3e-7" // m²/s
    @State private var lambda1: String = String(Double.pi)     // ≈ π

    // --- Résultat & UI ---
    @State private var tempsCalcule: Double = 0
    @State private var messageErreur: String?
    @State private var showHelp: Bool = true                   // Aide dépliée par défaut

    var body: some View {
        VStack(spacing: 20) {

            Text("🥚 Calcul du temps de cuisson d'un œuf à la coque")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.top)

            Form {
                Section(header: Text("Paramètres physiques")) {
                    labeledField("Rayon (m)", text: $rayon)
                    labeledField("Température de surface (°C)", text: $temperatureSurface)
                    labeledField("Température initiale (°C)", text: $temperatureInitiale)
                    labeledField("Température cible au cœur (°C)", text: $temperatureCible)
                    labeledField("Diffusivité thermique (m²/s)", text: $diffusiviteThermique)
                    labeledField("λ₁ (valeur propre)", text: $lambda1)
                }
                .font(.title2)
                .padding(.horizontal, 16)
                
                // --- AIDE & VALEURS TYPIQUES ---
                Section {
                    DisclosureGroup(isExpanded: $showHelp) {
                        helpContent
                            .padding(.vertical, 6)

                        presetsView
                    } label: {
                        Label("Aide & valeurs typiques", systemImage: "questionmark.circle")
                            .font(.title2)
                    }
                }
            }
            .formStyle(.grouped)
            .padding(.horizontal, 16)

            if let messageErreur = messageErreur {
                Text(messageErreur)
                    .foregroundColor(.red)
                    .font(.callout)
                    .padding(.top, 4)
            }

            Button("Calculer le temps de cuisson") {
                calculerTemps()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
            .font(.title2)

            if tempsCalcule > 0 {
                VStack(spacing: 6) {
                    Text("Temps de cuisson estimé :")
                    Text("\(String(format: "%.1f", tempsCalcule)) secondes")
                        .font(.headline)
                    Text("≈ \(Int(tempsCalcule / 60)) min \(Int(tempsCalcule.truncatingRemainder(dividingBy: 60))) s")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom)
            }

            Spacer()
        }
        .padding(.bottom)
    }

    // ---------------------------------------------------------
    // Champ étiqueté à droite, portable iOS/macOS
    // ---------------------------------------------------------
    func labeledField(_ label: String, text: Binding<String>) -> some View {
        LabeledContent(label) {
            TextField("", text: text)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.trailing)
            #if os(iOS)
                .keyboardType(.decimalPad) // uniquement iPhone/iPad
            #endif
        }
    }

    // ---------------------------------------------------------
    // Contenu de l'aide (explications synthétiques)
    // ---------------------------------------------------------
    private var helpContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Principe du modèle")
                .font(.title2)
            
            Text("""
            • On modélise l’œuf comme une sphère. La chaleur diffuse de la surface vers le centre.
            • La température au centre suit : T(0,t) = T0 + (Ts − T0) * (1 − e^{−λ1² α t / R²}).
            • Pour atteindre la température cible Tc : t = (R² / (λ1² α)) * ln((Ts − T0) / (Ts − Tc)).
            """)
            .fixedSize(horizontal: false, vertical: true)
            .font(.title2)
            Text("Rappels utiles")
                .font(.title2)
                .padding(.top, 4)
            
            Text("""
            • λ1 ≈ π pour une sphère (mode dominant).
            • Conditions pour un temps positif : Ts > Tc > T0.
            • Des écarts avec la pratique (3 min) viennent surtout de la taille de l'œuf (R), de Ts (98 vs 100 °C) et de Tc (63–65 °C).
            """)
            .fixedSize(horizontal: false, vertical: true)
            .font(.title2)
        }
    }

    // ---------------------------------------------------------
    // Vue des préréglages rapides (valeurs typiques)
    // ---------------------------------------------------------
    private var presetsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Préréglages rapides")
                .font(.title2)

            // Ligne tailles d'œufs
            HStack {
                presetButton("Œuf petit", hint: "R ≈ 0,017 m") {
                    applyPreset(r: 0.017, ts: nil, t0: 20, tc: nil)
                }
                presetButton("Œuf moyen", hint: "R ≈ 0,018 m") {
                    applyPreset(r: 0.018, ts: nil, t0: 20, tc: nil)
                }
                presetButton("Œuf gros", hint: "R ≈ 0,020 m") {
                    applyPreset(r: 0.020, ts: nil, t0: 20, tc: nil)
                }
            }

            // Ligne température de l'eau
            HStack {
                presetButton("Eau bouillante", hint: "Ts = 100 °C") {
                    applyPreset(r: nil, ts: 100, t0: nil, tc: nil)
                }
                presetButton("Eau frémissante", hint: "Ts = 98 °C") {
                    applyPreset(r: nil, ts: 98, t0: nil, tc: nil)
                }
            }

            // Ligne température cible
            HStack {
                presetButton("Jaune très coulant", hint: "Tc = 63 °C") {
                    applyPreset(r: nil, ts: nil, t0: nil, tc: 63)
                }
                presetButton("Jaune coulant", hint: "Tc = 64 °C") {
                    applyPreset(r: nil, ts: nil, t0: nil, tc: 64)
                }
                presetButton("Jaune crémeux", hint: "Tc = 65 °C") {
                    applyPreset(r: nil, ts: nil, t0: nil, tc: 65)
                }
            }

            // Raccourci “3 minutes cuisine” typique
            presetButton("Approcher 3 min cuisine", hint: "petit œuf, Ts=100 °C, Tc≈63 °C") {
                applyPreset(r: 0.017, ts: 100, t0: 20, tc: 63)
            }
            
        }
        .padding(.top, 6)
        
    }
        
    // Bouton de preset
    private func presetButton(_ title: String, hint: String? = nil, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Button(action: action) {
                Text(title)
                    .foregroundColor(.red)
            }
            .font(.title2)
            .buttonStyle(.bordered)
            .controlSize(.large)
            
            if let hint = hint {
                Text(hint).font(.caption).foregroundColor(.secondary)
            }
        }
    }

    // Appliquer un preset (ne modifie que les valeurs non nil)
    private func applyPreset(r: Double?, ts: Double?, t0: Double?, tc: Double?) {
        if let r = r { rayon = formatNumber(r) }
        if let ts = ts { temperatureSurface = formatNumber(ts) }
        if let t0 = t0 { temperatureInitiale = formatNumber(t0) }
        if let tc = tc { temperatureCible = formatNumber(tc) }
        // λ1 et α restent inchangés (π et 1.3e-7 par défaut)
    }

    private func formatNumber(_ value: Double) -> String {
        // Format simple pour rester lisible dans les TextField
        if abs(value) < 1e-3 || abs(value) > 1e4 {
            return String(format: "%g", value)
        } else {
            return String(value)
        }
    }

    // ---------------------------------------------------------
    // Calcul physique de t = (R² / (λ₁² α)) ln((T_s − T₀) / (T_s − 65))
    // ---------------------------------------------------------
    private func calculerTemps() {
        guard
            let R = Double(rayon), // R en mètres
            let Ts = Double(temperatureSurface), // T_s en °C
            let T0 = Double(temperatureInitiale), // T₀ en °C
            let Tc = Double(temperatureCible), // 65 en °C
            let alpha = Double(diffusiviteThermique), // α en m²/s
            let lambda = Double(lambda1) // λ₁ est égal à pi (le fameux rapport constant entre la circonfèrence d'un cercle et son diamètre quelque soit sa taille)
        else {
            messageErreur = "Veuillez entrer des valeurs numériques valides."
            tempsCalcule = 0
            return
        }

        if Tc <= T0 {
            messageErreur = "L'œuf est déjà à la température cible (ou en dessous)."
            tempsCalcule = 0
            return
        }
        if Tc >= Ts {
            messageErreur = "La température cible doit être strictement inférieure à la température de l'eau."
            tempsCalcule = 0
            return
        }

        let rapport = (Ts - T0) / (Ts - Tc)
        if rapport <= 0 {
            messageErreur = "Paramètres incohérents (logarithme non défini)."
            tempsCalcule = 0
            return
        }

        let t = (R * R) / (lambda * lambda * alpha) * log(rapport)
        tempsCalcule = max(0, t)// retourne la plus grande valeur entre 0 et t pour éviter les erreurs d’arrondi flottant
        messageErreur = nil
    }
}

