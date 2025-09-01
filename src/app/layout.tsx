import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'Nurse System - User Management',
  description: 'ระบบจัดการข้อมูลผู้ใช้งานสำหรับระบบพยาบาล พร้อมฟีเจอร์ Import และ Export ข้อมูล Excel',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="th">
      <body className={inter.className}>{children}</body>
    </html>
  )
}