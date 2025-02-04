import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to Nactions!")
                    .font(.largeTitle)
                    .padding()
                
                NavigationLink("Go to Settings", destination: SettingsView())
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
