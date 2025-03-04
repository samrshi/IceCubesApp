import SwiftUI
import Network
import Models
import Shimmer
import Status
import DesignSystem
import Env

public struct TimelineView: View {
  private enum Constants {
    static let scrollToTop = "top"
  }
  
  @Environment(\.scenePhase) private var scenePhase
  @EnvironmentObject private var theme: Theme
  @EnvironmentObject private var account: CurrentAccount
  @EnvironmentObject private var watcher: StreamWatcher
  @EnvironmentObject private var client: Client
  @StateObject private var viewModel = TimelineViewModel()
  @Binding var timeline: TimelineFilter
  
  private let feedbackGenerator = UIImpactFeedbackGenerator()
  
  public init(timeline: Binding<TimelineFilter>) {
    _timeline = timeline
  }
  
  public var body: some View {
    ScrollViewReader { proxy in
      ZStack(alignment: .top) {
        ScrollView {
          LazyVStack {
            tagHeaderView
              .padding(.bottom, 16)
              .id(Constants.scrollToTop)
            StatusesListView(fetcher: viewModel)
          }
          .padding(.top, DS.Constants.layoutPadding)
        }
        .background(theme.primaryBackgroundColor)
        if viewModel.pendingStatusesEnabled {
          makePendingNewPostsView(proxy: proxy)
        }
      }
    }
    .navigationTitle(timeline.title())
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      viewModel.client = client
      viewModel.timeline = timeline
    }
    .refreshable {
      feedbackGenerator.impactOccurred(intensity: 0.3)
      await viewModel.fetchStatuses(userIntent: true)
      feedbackGenerator.impactOccurred(intensity: 0.7)
    }
    .onChange(of: watcher.latestEvent?.id) { id in
      if let latestEvent = watcher.latestEvent {
        viewModel.handleEvent(event: latestEvent, currentAccount: account)
      }
    }
    .onChange(of: timeline) { newTimeline in
      viewModel.timeline = timeline
    }
    .onChange(of: scenePhase, perform: { scenePhase in
      switch scenePhase {
      case .active:
        Task {
          await viewModel.fetchStatuses(userIntent: false)
        }
      default:
        break
      }
    })
  }
  
  @ViewBuilder
  private func makePendingNewPostsView(proxy: ScrollViewProxy) -> some View {
    if !viewModel.pendingStatuses.isEmpty {
      Button {
        proxy.scrollTo(Constants.scrollToTop)
        withAnimation {
          viewModel.displayPendingStatuses()
        }
      } label: {
        Text(viewModel.pendingStatusesButtonTitle)
      }
      .buttonStyle(.bordered)
      .background(.thinMaterial)
      .cornerRadius(8)
      .padding(.top, 6)
    }
  }
  
  @ViewBuilder
  private var tagHeaderView: some View {
    if let tag = viewModel.tag {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text("#\(tag.name)")
            .font(.headline)
          Text("\(tag.totalUses) recent posts from \(tag.totalAccounts) participants")
            .font(.footnote)
            .foregroundColor(.gray)
        }
        Spacer()
        Button {
          Task {
            if tag.following {
              await viewModel.unfollowTag(id: tag.name)
            } else {
              await viewModel.followTag(id: tag.name)
            }
          }
        } label: {
          Text(tag.following ? "Following": "Follow")
        }.buttonStyle(.bordered)
      }
      .padding(.horizontal, DS.Constants.layoutPadding)
      .padding(.vertical, 8)
      .background(theme.secondaryBackgroundColor)
    }
  }
}
