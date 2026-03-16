import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showCategoryMenu = false
    @State private var showSubCategoryMenu = false
    @State private var showAreaMenu = false
    @State private var showDistrictMenu = false
    
    var onSelectProduct: ((AdItem) -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Container
            VStack(spacing: 10) {
                // Row 1: Categories
                HStack(spacing: 10) {
                    FilterButton(title: categoryTitle) {
                        showCategoryMenu = true
                    }
                    .confirmationDialog("카테고리 선택", isPresented: $showCategoryMenu) {
                        Button("전체") {
                            viewModel.selectedCategoryMid = "ALL"
                            viewModel.selectedCategoryScls = "ALL"
                            viewModel.loadInitialData()
                        }
                        ForEach(viewModel.categories, id: \.strIdx) { cat in
                            Button(cat.strMsg ?? "") {
                                viewModel.selectedCategoryMid = cat.strIdx ?? "ALL"
                                viewModel.selectedCategoryScls = "ALL"
                                viewModel.loadSubCategories(mcode: viewModel.selectedCategoryMid)
                                viewModel.loadInitialData()
                            }
                        }
                    }
                    
                    FilterButton(title: subCategoryTitle) {
                        showSubCategoryMenu = true
                    }
                    .confirmationDialog("세부항목 선택", isPresented: $showSubCategoryMenu) {
                        Button("전체") {
                            viewModel.selectedCategoryScls = "ALL"
                            viewModel.loadInitialData()
                        }
                        ForEach(viewModel.subCategories, id: \.strIdx) { sub in
                            Button(sub.strMsg ?? "") {
                                viewModel.selectedCategoryScls = sub.strIdx ?? "ALL"
                                viewModel.loadInitialData()
                            }
                        }
                    }
                }
                
                // Row 2: Areas
                HStack(spacing: 10) {
                    FilterButton(title: areaTitle) {
                        showAreaMenu = true
                    }
                    .confirmationDialog("도시 선택", isPresented: $showAreaMenu) {
                        Button("전체") {
                            viewModel.selectedAreaMid = "ALL"
                            viewModel.selectedAreaScls = "ALL"
                            viewModel.loadInitialData()
                        }
                        ForEach(viewModel.areas, id: \.strIdx) { area in
                            Button(area.strMsg ?? "") {
                                viewModel.selectedAreaMid = area.strIdx ?? "ALL"
                                viewModel.selectedAreaScls = "ALL"
                                viewModel.loadDistricts(mcode: viewModel.selectedAreaMid)
                                viewModel.loadInitialData()
                            }
                        }
                    }
                    
                    FilterButton(title: districtTitle) {
                        showDistrictMenu = true
                    }
                    .confirmationDialog("시구 선택", isPresented: $showDistrictMenu) {
                        Button("전체") {
                            viewModel.selectedAreaScls = "ALL"
                            viewModel.loadInitialData()
                        }
                        ForEach(viewModel.districts, id: \.strIdx) { dist in
                            Button(dist.strMsg ?? "") {
                                viewModel.selectedAreaScls = dist.strIdx ?? "ALL"
                                viewModel.loadInitialData()
                            }
                        }
                    }
                }
                
                // Row 3: Switches
                HStack(spacing: 10) {
                    HStack {
                        Text("판매중인 상품보기")
                            .font(.system(size: 14))
                        Spacer()
                        Toggle("", isOn: $viewModel.isSaleOnly)
                            .labelsHidden()
                            .onChange(of: viewModel.isSaleOnly) { _ in viewModel.loadInitialData() }
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    
                    HStack {
                        Text("희망단가로 조회")
                            .font(.system(size: 14))
                        Spacer()
                        Toggle("", isOn: $viewModel.isPriceFilterOn)
                            .labelsHidden()
                            .onChange(of: viewModel.isPriceFilterOn) { _ in viewModel.loadInitialData() }
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                }
                
                // Row 4: Price Slider (Conditionally shown)
                if viewModel.isPriceFilterOn {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("희망단가: \(formattedPrice(viewModel.minPrice))원 ~ \(formattedPrice(viewModel.maxPrice))원")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        // Simple dual slider replacement or instruction
                        HStack {
                            Slider(value: $viewModel.minPrice, in: 0...viewModel.maxPrice, step: 10000)
                            Slider(value: $viewModel.maxPrice, in: viewModel.minPrice...9990000, step: 10000)
                        }
                        
                        Button(action: {
                            viewModel.loadInitialData()
                        }) {
                            Text("조회")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding(.top, 5)
                    .transition(.opacity)
                }
            }
            .padding(10)
            .background(Color(.systemBackground))
            
            // Product List
            ZStack {
                List {
                    ForEach(viewModel.items, id: \.productId) { item in
                        Button(action: {
                            onSelectProduct?(item)
                        }) {
                            ProductRowView(item: item)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .onAppear {
                            if item.productId == viewModel.items.last?.productId {
                                viewModel.fetchProducts()
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    viewModel.loadInitialData()
                }
                
                if viewModel.items.isEmpty && !viewModel.isLoading {
                    Text("데이터가 없습니다.")
                        .foregroundColor(.secondary)
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
        }
        .onAppear {
            viewModel.loadFilterData()
            viewModel.loadInitialData()
        }
    }
    
    // Helper titles
    private var categoryTitle: String {
        viewModel.categories.first(where: { $0.strIdx == viewModel.selectedCategoryMid })?.strMsg ?? "카테고리"
    }
    private var subCategoryTitle: String {
        viewModel.subCategories.first(where: { $0.strIdx == viewModel.selectedCategoryScls })?.strMsg ?? "세부항목"
    }
    private var areaTitle: String {
        viewModel.areas.first(where: { $0.strIdx == viewModel.selectedAreaMid })?.strMsg ?? "도시선택"
    }
    private var districtTitle: String {
        viewModel.districts.first(where: { $0.strIdx == viewModel.selectedAreaScls })?.strMsg ?? "시구선택"
    }
    
    private func formattedPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: Int(price))) ?? "0"
    }
}

// Custom Filter Button
struct FilterButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .lineLimit(1)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .bold))
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.black)
            .padding(.horizontal, 12)
            .frame(height: 38)
            .frame(maxWidth: .infinity)
            .background(Color(white: 0.95))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
        }
    }
}
