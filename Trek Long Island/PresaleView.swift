// Copyright Bryan Carroll. All rights reserved.
//  PresaleView.swift
//  Trek Long Island
//
//  Tickets info screen:
//  • Official purchase links
//  • Promo image
//  • Uses your themed background color
//
//  NOTE: Ensure an asset named "unnamed" exists in Assets.xcassets.

import SwiftUI

struct PresaleView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Official Purchase Links")
                    .font(.headline)
                    .padding(.top)

                VStack(spacing: 10) {
                    Link(destination: TicketPurchaseLinks.admissionURL) {
                        Label("2027 Tickets", systemImage: "ticket.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Link(destination: TicketPurchaseLinks.photoOpsURL) {
                        Label("Photo Ops", systemImage: "camera.viewfinder")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if TicketPurchaseLinks.areAutographPreSalesAvailable() {
                        Link(destination: TicketPurchaseLinks.autographPreSalesURL) {
                            Label("Autograph Pre-Sales", systemImage: "pencil.and.scribble")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Label("Autograph Pre-Sales Closed", systemImage: "pencil.slash")
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(Color.primary.opacity(0.08))
                            )
                            .foregroundStyle(Color.primary.opacity(0.72))
                    }

                    Link(destination: TicketPurchaseLinks.vendorTablingURL) {
                        Label("Vendor Tabling", systemImage: "storefront")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Image("Trek Long Island Black")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 340)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(radius: 6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(.separator.opacity(0.2))
                    )
            }
            .frame(maxWidth: 560)
            .padding()
        }
        .background(Color("PrimaryBackground").ignoresSafeArea())
        .navigationTitle("Tickets")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { PresaleView() }
}
