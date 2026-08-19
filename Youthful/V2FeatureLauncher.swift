import SwiftUI
import SwiftData

// The old V2FeatureLauncher has been removed. The app now uses the unified
// AssistiveTouch-style launcher in YouthfulApp.swift. This file retains the
// smart-feature destination views used by that unified launcher.

struct V2FeatureMenu: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFeature: SmartFeature?

    enum SmartFeature: String, Identifiable {
        case progress, intelligence, reminders, photos, discovery
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 5) {
                            CapsuleLabel(text: "Youthful 2")
                            Text("Smart tools").font(.system(size: 34, weight: .semibold, design: .serif))
                            Text("Everything added to make your routine more useful, measurable and personal.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
                        }
                        featureButton(.discovery, "Discover Products", "Explore a curated Philippine-market personal-care catalog and add products to your library.", "bag.fill")
                        featureButton(.progress, "My Progress", "Streaks, completion, recommendations and product health.", "chart.xyaxis.line")
                        featureButton(.intelligence, "Product Intelligence", "Opened dates, run-out estimates, expiration and notes.", "drop.circle.fill")
                        featureButton(.reminders, "Smart Reminders", "Morning, evening and custom reminder times.", "bell.badge.fill")
                        featureButton(.photos, "Compare Progress Photos", "Add photos from your library or camera, then compare two dates side-by-side.", "rectangle.split.2x1")
                    }.padding(20).padding(.bottom, 30)
                }
            }
            .navigationTitle("Smart tools")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { CoachHaptics.selection(); dismiss() } } }
        }
        .sheet(item: $selectedFeature) { feature in SmartFeatureSheet(feature: feature) }
    }

    private func featureButton(_ feature: SmartFeature, _ title: String, _ detail: String, _ icon: String) -> some View {
        Button { CoachHaptics.selection(); selectedFeature = feature } label: {
            PremiumCard { HStack(spacing: 13) {
                Image(systemName: icon).font(.title3).frame(width: 46, height: 46).background(PremiumTheme.cream).clipShape(Circle())
                VStack(alignment: .leading, spacing: 4) { Text(title).font(.subheadline.weight(.semibold)); Text(detail).font(.caption).foregroundStyle(PremiumTheme.muted).lineLimit(2) }
                Spacer(); Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(PremiumTheme.muted)
            } }
        }.buttonStyle(.plain)
    }
}

private struct SmartFeatureSheet: View {
    @Environment(\.dismiss) private var dismiss
    let feature: V2FeatureMenu.SmartFeature
    var body: some View {
        ZStack(alignment: .topTrailing) {
            destination.padding(.top, 8)
            Button { CoachHaptics.selection(); dismiss() } label: {
                Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundStyle(PremiumTheme.ink).frame(width: 34, height: 34).background(.ultraThinMaterial).clipShape(Circle()).shadow(color: .black.opacity(0.08), radius: 8, y: 3)
            }.buttonStyle(.plain).padding(.trailing, 18).padding(.top, 8).accessibilityLabel("Close smart feature")
        }
    }
    @ViewBuilder private var destination: some View {
        switch feature {
        case .discovery: ProductDiscoveryView()
        case .progress: SmartFeaturesView()
        case .intelligence: ProductIntelligenceView()
        case .reminders: SmartRemindersView()
        case .photos: ProgressPhotoCaptureView()
        }
    }
}

// MARK: - Philippine Product Discovery

struct DiscoveryProduct: Identifiable, Hashable {
    let id: String
    let name: String
    let brand: String
    let category: String
    let purpose: [String]
    let ingredients: [String]
    let skinTypes: [String]
    let priceTier: String
    let priceNote: String
    let availability: String
    let whyRecommended: String
    let retailerURL: String?

    static let catalog: [DiscoveryProduct] = [
        .init(id: "belo-sunscreen", name: "Belo SunExpert Face Cover SPF 40", brand: "Belo", category: "Sunscreen", purpose: ["Sun protection"], ingredients: ["UV filters"], skinTypes: ["Normal", "Combination", "Oily"], priceTier: "₱₱", priceNote: "Mid-range", availability: "Commonly available in the Philippines", whyRecommended: "A practical daily sunscreen option for users who want straightforward sun protection.", retailerURL: "https://www.watsons.com.ph/"),
        .init(id: "cetaphil-moisturizer", name: "Moisturizing Lotion", brand: "Cetaphil", category: "Moisturizer", purpose: ["Moisturizing", "Barrier support"], ingredients: ["Glycerin", "Humectants"], skinTypes: ["Normal", "Dry", "Sensitive"], priceTier: "₱₱", priceNote: "Mid-range", availability: "Widely available in Philippine retailers", whyRecommended: "A simple moisturizer choice for maintaining comfortable, hydrated skin.", retailerURL: "https://www.watsons.com.ph/"),
        .init(id: "celeteque-cleanser", name: "Hydration Facial Wash", brand: "Celeteque", category: "Cleanser", purpose: ["Cleansing", "Hydration"], ingredients: ["Hydrating agents"], skinTypes: ["Normal", "Combination", "Sensitive"], priceTier: "₱", priceNote: "Budget", availability: "Widely available in the Philippines", whyRecommended: "An accessible everyday cleanser for a simple routine.", retailerURL: "https://www.watsons.com.ph/"),
        .init(id: "luxe-organix-niacinamide", name: "Niacinamide Serum", brand: "Luxe Organix", category: "Brightening", purpose: ["Brightening", "Uneven tone", "Post-acne marks"], ingredients: ["Niacinamide"], skinTypes: ["Normal", "Combination", "Oily"], priceTier: "₱", priceNote: "Budget", availability: "Commonly available in the Philippines", whyRecommended: "A focused option for users interested in improving the appearance of uneven-looking tone.", retailerURL: "https://www.watsons.com.ph/"),
        .init(id: "ponds-brightening", name: "Bright Beauty Facial Foam", brand: "POND'S", category: "Brightening", purpose: ["Cleansing", "Dull-looking skin"], ingredients: ["Brightening ingredients"], skinTypes: ["Normal", "Combination"], priceTier: "₱", priceNote: "Budget", availability: "Widely available in the Philippines", whyRecommended: "An inexpensive cleanser for users who want a simple brightening-oriented routine.", retailerURL: "https://www.watsons.com.ph/"),
        .init(id: "garnier-vitamin-c", name: "Vitamin C Brightening Serum", brand: "Garnier", category: "Brightening", purpose: ["Brightening", "Dark spots"], ingredients: ["Vitamin C"], skinTypes: ["Normal", "Combination", "Oily"], priceTier: "₱₱", priceNote: "Mid-range", availability: "Available through Philippine beauty retailers", whyRecommended: "A targeted brightening option for users focusing on the appearance of dark spots and uneven tone.", retailerURL: "https://www.watsons.com.ph/"),
        .init(id: "belo-body-sunscreen", name: "SunExpert Body Shield SPF 50", brand: "Belo", category: "Body Care", purpose: ["Sun protection", "Outdoor use"], ingredients: ["UV filters"], skinTypes: ["Normal", "Combination", "Oily"], priceTier: "₱₱", priceNote: "Mid-range", availability: "Commonly available in the Philippines", whyRecommended: "Useful for users who want sun protection beyond the face, especially during outdoor exposure.", retailerURL: "https://www.watsons.com.ph/"),
        .init(id: "luxe-hair", name: "Premium Keratin Shampoo", brand: "Luxe Organix", category: "Hair Care", purpose: ["Hair cleansing", "Hair care"], ingredients: ["Keratin"], skinTypes: ["All"], priceTier: "₱", priceNote: "Budget", availability: "Commonly available in the Philippines", whyRecommended: "An accessible hair-care option that can sit alongside a simple grooming routine.", retailerURL: "https://www.watsons.com.ph/"),
        .init(id: "belo-lip", name: "Lip Balm", brand: "Belo", category: "Lip Care", purpose: ["Lip care", "Moisturizing"], ingredients: ["Emollients"], skinTypes: ["All"], priceTier: "₱", priceNote: "Budget", availability: "Commonly available in the Philippines", whyRecommended: "A simple add-on for maintaining comfortable lips throughout the day.", retailerURL: "https://www.watsons.com.ph/")
    ]
}

struct ProductDiscoveryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var selectedCategory = "All"
    @State private var searchText = ""
    @State private var selectedProduct: DiscoveryProduct?
    @Query private var products: [Product]

    private let categories = ["All", "Sunscreen", "Moisturizer", "Cleanser", "Brightening", "Body Care", "Hair Care", "Lip Care"]
    private var filteredProducts: [DiscoveryProduct] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return DiscoveryProduct.catalog.filter { product in
            (selectedCategory == "All" || product.category == selectedCategory) &&
            (query.isEmpty || product.name.localizedCaseInsensitiveContains(query) || product.brand.localizedCaseInsensitiveContains(query) || product.ingredients.joined(separator: " ").localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) { header; categoryPicker; searchField; productList }
                        .padding(20).padding(.bottom, 32)
                }
            }
            .navigationTitle("Discover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { CoachHaptics.selection(); dismiss() } } }
            .sheet(item: $selectedProduct) { product in ProductDiscoveryDetail(product: product) }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            CapsuleLabel(text: "Philippines")
            Text("Discover products").font(.system(size: 34, weight: .semibold, design: .serif))
            Text("A curated starting catalog for personal care and grooming products commonly found in the Philippine market.").font(.subheadline).foregroundStyle(PremiumTheme.muted)
        }
    }
    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 8) {
            ForEach(categories, id: \.self) { category in
                Button { selectedCategory = category; CoachHaptics.selection() } label: {
                    Text(category).font(.caption.weight(.semibold)).foregroundStyle(selectedCategory == category ? PremiumTheme.cream : PremiumTheme.ink).padding(.horizontal, 13).padding(.vertical, 9).background(selectedCategory == category ? PremiumTheme.ink : PremiumTheme.card).clipShape(Capsule())
                }.buttonStyle(.plain)
            }
        } }
    }
    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass").foregroundStyle(PremiumTheme.muted)
            TextField("Search products, brands or ingredients", text: $searchText).textInputAutocapitalization(.never)
            if !searchText.isEmpty { Button { searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(PremiumTheme.muted) }.buttonStyle(.plain) }
        }.padding(.horizontal, 14).frame(height: 48).background(PremiumTheme.card).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    private var productList: some View {
        VStack(spacing: 12) {
            ForEach(filteredProducts) { product in
                Button { selectedProduct = product; CoachHaptics.selection() } label: { ProductDiscoveryCard(product: product, isAdded: products.contains { $0.name == product.name }) }.buttonStyle(.plain)
            }
            if filteredProducts.isEmpty { PremiumCard { VStack(alignment: .leading, spacing: 7) { Text("No matches").font(.headline); Text("Try another category or search term.").font(.caption).foregroundStyle(PremiumTheme.muted) } } }
        }
    }
}

private struct ProductDiscoveryCard: View {
    let product: DiscoveryProduct
    let isAdded: Bool
    var body: some View {
        PremiumCard { HStack(spacing: 13) {
            Image(systemName: icon).font(.title3).frame(width: 48, height: 48).background(PremiumTheme.cream).clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) { Text(product.brand.uppercased()).font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1.1).foregroundStyle(PremiumTheme.muted); if isAdded { Image(systemName: "checkmark.circle.fill").font(.caption).foregroundStyle(PremiumTheme.sage) } }
                Text(product.name).font(.subheadline.weight(.semibold)).foregroundStyle(PremiumTheme.ink)
                Text(product.purpose.joined(separator: " • ")).font(.caption).foregroundStyle(PremiumTheme.muted).lineLimit(1)
            }
            Spacer(); VStack(alignment: .trailing, spacing: 5) { Text(product.priceTier).font(.caption.weight(.bold)); Image(systemName: "chevron.right").font(.caption.weight(.bold)).foregroundStyle(PremiumTheme.muted) }
        } }
    }
    private var icon: String {
        switch product.category { case "Sunscreen": return "sun.max.fill"; case "Moisturizer": return "humidity.fill"; case "Cleanser": return "drop.fill"; case "Brightening": return "sparkles"; case "Body Care": return "figure.stand"; case "Hair Care": return "scissors"; case "Lip Care": return "heart.fill"; default: return "bag.fill" }
    }
}

private struct ProductDiscoveryDetail: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let product: DiscoveryProduct
    @Query private var savedProducts: [Product]
    private var saved: Product? { savedProducts.first { $0.name == product.name } }

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        PremiumCard { VStack(alignment: .leading, spacing: 10) {
                            CapsuleLabel(text: product.category)
                            Text(product.name).font(.system(size: 29, weight: .semibold, design: .serif))
                            Text(product.brand).font(.subheadline.weight(.semibold)).foregroundStyle(PremiumTheme.muted)
                            HStack { Text(product.priceTier).font(.headline); Text(product.priceNote).font(.caption).foregroundStyle(PremiumTheme.muted); Spacer(); Text("PH market").font(.caption.weight(.semibold)) }
                        } }
                        infoSection("Why it is listed", product.whyRecommended)
                        infoSection("Purpose", product.purpose.joined(separator: " • "))
                        infoSection("Key ingredients", product.ingredients.joined(separator: " • "))
                        infoSection("Suitable skin types", product.skinTypes.joined(separator: " • "))
                        infoSection("Availability", product.availability)
                        if let urlString = product.retailerURL, let url = URL(string: urlString) {
                            Link(destination: url) { Label("View Philippine retailer", systemImage: "arrow.up.right.square").font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(15).foregroundStyle(PremiumTheme.cream).background(PremiumTheme.ink).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous)) }
                        }
                        Button {
                            if let saved { context.delete(saved) } else { context.insert(Product(name: product.name, category: product.category, notes: "Discovered in Youthful Glow • \(product.purpose.joined(separator: ", "))")) }
                            try? context.save(); CoachHaptics.success()
                        } label: {
                            Label(saved == nil ? "Add to My Products" : "Remove from My Products", systemImage: saved == nil ? "plus.circle.fill" : "checkmark.circle.fill").font(.subheadline.weight(.bold)).frame(maxWidth: .infinity).padding(15).foregroundStyle(saved == nil ? PremiumTheme.ink : PremiumTheme.sage).background(PremiumTheme.card).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        }.buttonStyle(.plain)
                        Text("Product information can change. Check the current package label and seller information before purchasing. Popularity or availability does not by itself establish effectiveness.").font(.caption).foregroundStyle(PremiumTheme.muted).padding(.horizontal, 4)
                    }.padding(20).padding(.bottom, 30)
                }
            }
            .navigationTitle("Product details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }
    private func infoSection(_ title: String, _ value: String) -> some View { PremiumCard { VStack(alignment: .leading, spacing: 7) { Text(title).font(.caption.weight(.bold)).foregroundStyle(PremiumTheme.muted); Text(value).font(.subheadline) } } }
}
