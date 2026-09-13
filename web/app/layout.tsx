import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  metadataBase: new URL("https://closet.enci.dev"),
  title: {
    default: "closet",
    template: "%s · closet",
  },
  description: "Browse Eric's clothes and send him an outfit.",
  applicationName: "closet",
  openGraph: {
    title: "closet",
    description: "Browse Eric's clothes and send him an outfit.",
    type: "website",
    siteName: "closet",
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-dvh bg-background text-foreground">{children}</body>
    </html>
  );
}
