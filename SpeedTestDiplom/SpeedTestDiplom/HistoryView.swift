import SwiftUI
import CoreData

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TestResult.date, ascending: false)],
        animation: .default)
    private var results: FetchedResults<TestResult>
    
    @State private var showDeleteAllAlert = false
    
    var body: some View {
        NavigationStack{
            List{
                ForEach(results){ result in
                    ZStack{
                        NavigationLink(destination: TestDetailView(result: result)){
                            EmptyView()
                        }
                        .opacity(0)
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(result.date?.formatted(date: .numeric, time: .shortened) ?? "")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .padding(.leading, 20)
                            ResultCardView(result: result)
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }
                .onDelete(perform: deleteResults)
            }
            .listStyle(.plain)
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button{
                        dismiss()
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing){
                    Button{
                        showDeleteAllAlert = true
                    } label: {
                        Label("Clear History", systemImage: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Do you want to clear history?", isPresented: $showDeleteAllAlert){
                Button("Cancel", role: .cancel){}
                Button("Delete All", role: .destructive){
                    deleteAll()
                }
            } message: {
                Text("This action cannot be undone.")
            }
        }
        
    }

    private func deleteResults(offsets: IndexSet) {
        StorageManager.shared.deleteResult(at: offsets, in: results)
    }
    
    private func deleteAll(){
        StorageManager.shared.deleteAllHistory(results: results)
    }
}

#Preview {
    let context = PersistenceController.shared.container.viewContext
    return HistoryView()
        .environment(\.managedObjectContext, context)
}
