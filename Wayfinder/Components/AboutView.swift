// Wayfinder

import SwiftUI

fileprivate let aboutText: String =
"""
Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

Felis imperdiet proin fermentum leo vel orci porta. Egestas egestas fringilla phasellus faucibus. Sed id semper risus in hendrerit gravida rutrum. Nunc faucibus a pellentesque sit amet porttitor eget. Arcu dictum varius duis at consectetur lorem donec massa sapien. Praesent tristique magna sit amet purus. Sed egestas egestas fringilla phasellus faucibus scelerisque eleifend donec pretium. Dignissim enim sit amet venenatis. Mi ipsum faucibus vitae aliquet nec ullamcorper. Aliquet bibendum enim facilisis gravida neque convallis a cras semper. Fermentum iaculis eu non diam. Ornare arcu odio ut sem.
"""

struct AboutView: View {
    var body: some View {
        ScrollView {
            Text("About the App").font(.title).padding()
            Text(aboutText).padding()
            Spacer()
        }.padding()
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
