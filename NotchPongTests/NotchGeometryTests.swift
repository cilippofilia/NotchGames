import CoreGraphics
import Testing
@testable import NotchPong

struct NotchGeometryTests {
    @Test func notchRectSitsBetweenAuxiliaryAreas() {
        let geometry = NotchGeometry.make(
            screenFrame: CGRect(x: 0, y: 0, width: 1512, height: 982),
            safeAreaTop: 32,
            auxiliaryTopLeft: CGRect(x: 0, y: 950, width: 661, height: 32),
            auxiliaryTopRight: CGRect(x: 851, y: 950, width: 661, height: 32)
        )
        #expect(geometry == NotchGeometry(notchRect: CGRect(x: 661, y: 950, width: 190, height: 32), menuBarHeight: 32))
    }

    @Test func noNotchReturnsNil() {
        let geometry = NotchGeometry.make(
            screenFrame: CGRect(x: 0, y: 0, width: 1920, height: 1080),
            safeAreaTop: 0,
            auxiliaryTopLeft: nil,
            auxiliaryTopRight: nil
        )
        #expect(geometry == nil)
    }

    @Test func offsetScreenKeepsNotchInScreenCoordinates() {
        // Second display placed to the right of the main one.
        let geometry = NotchGeometry.make(
            screenFrame: CGRect(x: 1920, y: 0, width: 1512, height: 982),
            safeAreaTop: 32,
            auxiliaryTopLeft: CGRect(x: 1920, y: 950, width: 661, height: 32),
            auxiliaryTopRight: CGRect(x: 2771, y: 950, width: 661, height: 32)
        )
        #expect(geometry?.notchRect.minX == 2581)
    }
}
