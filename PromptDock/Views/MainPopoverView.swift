import AppKit
import SwiftUI

struct MainPopoverView: View {
    @ObservedObject var viewModel: PromptDockViewModel

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                header
                Divider()
                TabView {
                    PromptEditorView(viewModel: viewModel)
                        .tabItem {
                            Label("优化", systemImage: "wand.and.stars")
                        }

                    HistoryView(viewModel: viewModel)
                        .tabItem {
                            Label("历史", systemImage: "clock.arrow.circlepath")
                        }
                }
            }

            WindowResizeHandle()
                .frame(width: 22, height: 22)
                .padding(7)
                .help("拖动调整窗口大小")
        }
        .frame(minWidth: 860, minHeight: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.badge.star")
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("PromptDock")
                    .font(.headline)
                Text("面向 AI 编程助手的提示词优化器")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                NotificationCenter.default.post(name: .promptDockOpenSettings, object: nil)
            } label: {
                Image(systemName: "gearshape")
            }
            .buttonStyle(.borderless)
            .help("设置")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct WindowResizeHandle: NSViewRepresentable {
    func makeNSView(context: Context) -> ResizeHandleView {
        ResizeHandleView()
    }

    func updateNSView(_ nsView: ResizeHandleView, context: Context) {}
}

private final class ResizeHandleView: NSView {
    private var initialWindowFrame: NSRect?
    private var initialMouseLocation: NSPoint?
    private var initialVisibleFrame: NSRect?
    private var didPushCursor = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 5
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.cornerRadius = 5
    }

    override var acceptsFirstResponder: Bool {
        true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .closedHand)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor.tertiaryLabelColor.setStroke()
        let path = NSBezierPath()
        path.lineWidth = 1.5
        path.lineCapStyle = .round

        let lines: [(CGFloat, CGFloat)] = [(13, 4), (9, 4), (5, 4)]
        for (startOffset, endOffset) in lines {
            path.move(to: NSPoint(x: bounds.maxX - startOffset, y: bounds.minY + 3))
            path.line(to: NSPoint(x: bounds.maxX - 3, y: bounds.minY + endOffset + 9))
        }

        path.stroke()
    }

    override func mouseDown(with event: NSEvent) {
        initialWindowFrame = window?.frame
        initialMouseLocation = NSEvent.mouseLocation
        initialVisibleFrame = window?.screen?.visibleFrame ?? NSScreen.main?.visibleFrame
        NSCursor.closedHand.push()
        didPushCursor = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard
            let window,
            let initialWindowFrame,
            let initialMouseLocation
        else {
            return
        }

        let currentMouseLocation = NSEvent.mouseLocation
        let deltaX = currentMouseLocation.x - initialMouseLocation.x
        let deltaY = currentMouseLocation.y - initialMouseLocation.y
        let minimumSize = window.minSize
        let requestedWidth = max(minimumSize.width, initialWindowFrame.width + deltaX)
        let requestedHeight = max(minimumSize.height, initialWindowFrame.height - deltaY)
        let width = clampedWidth(requestedWidth, minimumSize: minimumSize, initialFrame: initialWindowFrame)
        let height = clampedHeight(requestedHeight, minimumSize: minimumSize, initialFrame: initialWindowFrame)
        let frame = NSRect(
            x: initialWindowFrame.minX,
            y: initialWindowFrame.maxY - height,
            width: width,
            height: height
        )

        window.setFrame(frame, display: true)
    }

    override func mouseUp(with event: NSEvent) {
        initialWindowFrame = nil
        initialMouseLocation = nil
        initialVisibleFrame = nil
        if didPushCursor {
            NSCursor.pop()
            didPushCursor = false
        }
    }

    private func clampedWidth(_ width: CGFloat, minimumSize: NSSize, initialFrame: NSRect) -> CGFloat {
        guard let initialVisibleFrame else {
            return width
        }

        let maximumWidth = max(minimumSize.width, initialVisibleFrame.maxX - initialFrame.minX)
        return min(width, maximumWidth)
    }

    private func clampedHeight(_ height: CGFloat, minimumSize: NSSize, initialFrame: NSRect) -> CGFloat {
        guard let initialVisibleFrame else {
            return height
        }

        let maximumHeight = max(minimumSize.height, initialFrame.maxY - initialVisibleFrame.minY)
        return min(height, maximumHeight)
    }
}
