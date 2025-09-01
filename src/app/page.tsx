'use client'

import { useState } from 'react'
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Download, FileDown, Upload, Menu, CheckCircle, AlertCircle, Users, Database, FileSpreadsheet, Settings } from 'lucide-react'

export default function NurseSystemDemo() {
  const [isDownloading, setIsDownloading] = useState(false)
  const [downloadSuccess, setDownloadSuccess] = useState(false)

  const handleDownload = async (type: 'data' | 'template') => {
    setIsDownloading(true)
    // Simulate download
    await new Promise(resolve => setTimeout(resolve, 2000))
    setIsDownloading(false)
    setDownloadSuccess(true)
    setTimeout(() => setDownloadSuccess(false), 3000)
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-green-50 to-emerald-50">
      {/* Header */}
      <header className="bg-white shadow-sm border-b">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <div className="p-3 bg-gradient-to-r from-emerald-500 to-green-600 rounded-xl shadow-lg">
                <Database className="h-6 w-6 text-white" />
              </div>
              <div>
                <h1 className="text-2xl font-bold text-gray-900">ระบบจัดการข้อมูลผู้ใช้งาน</h1>
                <p className="text-gray-600">เพิ่ม แก้ไข และติดตามข้อมูลผู้ใช้โรคไม่ติดต่อเรื้อรัง</p>
              </div>
            </div>
            
            {/* Download Template Buttons - ในมุมขวาบน */}
            <div className="flex items-center space-x-3">
              {/* ปุ่ม Download ข้อมูลปัจจุบัน */}
              <Button
                onClick={() => handleDownload('data')}
                disabled={isDownloading}
                className="bg-gradient-to-r from-emerald-500 to-green-600 hover:from-emerald-600 hover:to-green-700 text-white shadow-md transition-all duration-200"
              >
                <Download className="h-4 w-4 mr-2" />
                ดาวน์โหลดข้อมูล
              </Button>

              {/* ปุ่ม Download Template ว่าง */}
              <Button
                onClick={() => handleDownload('template')}
                disabled={isDownloading}
                variant="outline"
                className="border-2 border-emerald-500 text-emerald-600 hover:bg-emerald-50 shadow-md transition-all duration-200"
              >
                <FileDown className="h-4 w-4 mr-2" />
                Template ว่าง
              </Button>

              {/* Menu เพิ่มเติม */}
              <div className="relative">
                <Button
                  variant="outline"
                  size="icon"
                  className="border-gray-300 hover:bg-gray-50 shadow-md"
                >
                  <Menu className="h-4 w-4" />
                </Button>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Success Notification */}
      {downloadSuccess && (
        <div className="fixed top-4 right-4 z-50">
          <div className="bg-green-500 text-white px-6 py-3 rounded-lg shadow-lg flex items-center space-x-2 animate-in slide-in-from-top">
            <CheckCircle className="h-5 w-5" />
            <span>ดาวน์โหลดสำเร็จ!</span>
          </div>
        </div>
      )}

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* Left Panel - User Form */}
          <Card className="lg:col-span-1 shadow-xl border-0 bg-white/70 backdrop-blur">
            <CardHeader className="pb-4">
              <div className="flex items-center space-x-3">
                <div className="p-2 bg-gradient-to-r from-emerald-500 to-green-600 rounded-lg">
                  <Users className="h-5 w-5 text-white" />
                </div>
                <div>
                  <CardTitle className="text-lg text-gray-900">เพิ่มผู้ใช้ใหม่</CardTitle>
                  <CardDescription>กรอกข้อมูลผู้ใช้งานในระบบ</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="space-y-4">
              {/* Form fields simulation */}
              <div className="space-y-3">
                <div className="h-12 bg-gray-100 rounded-lg flex items-center px-3">
                  <span className="text-gray-500">เลขบัตรประจำตัวประชาชน</span>
                </div>
                <div className="h-12 bg-gray-100 rounded-lg flex items-center px-3">
                  <span className="text-gray-500">ชื่อ-นามสกุล</span>
                </div>
                <div className="h-12 bg-gray-100 rounded-lg flex items-center px-3">
                  <span className="text-gray-500">เบอร์โทร</span>
                </div>
                <div className="h-12 bg-gray-100 rounded-lg flex items-center px-3">
                  <span className="text-gray-500">อายุ</span>
                </div>
                
                {/* Tech Level Section */}
                <div className="p-4 bg-blue-50 rounded-lg border border-blue-200">
                  <div className="flex items-center space-x-2 mb-2">
                    <Settings className="h-4 w-4 text-blue-600" />
                    <span className="font-medium text-blue-800">ความเก่งด้านเทคโนโลยี</span>
                  </div>
                  <div className="space-y-2">
                    <Badge variant="outline" className="border-red-200 text-red-700 bg-red-50">
                      ไม่เก่งเทคโนโลยี (ต้องดูแลพิเศษ)
                    </Badge>
                    <p className="text-xs text-gray-600 italic">
                      * สำหรับจัดกลุ่มการดูแลและระบุความต้องการช่วยเหลือพิเศษ
                    </p>
                  </div>
                </div>
              </div>

              <div className="flex space-x-2 pt-4">
                <Button className="flex-1 bg-emerald-500 hover:bg-emerald-600">
                  เพิ่มผู้ใช้
                </Button>
                <Button variant="outline" className="flex-none border-emerald-500 text-emerald-600">
                  <Upload className="h-4 w-4 mr-1" />
                  Import Excel
                </Button>
              </div>
            </CardContent>
          </Card>

          {/* Right Panel - User List */}
          <Card className="lg:col-span-2 shadow-xl border-0 bg-white/70 backdrop-blur">
            <CardHeader className="pb-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center space-x-3">
                  <div className="p-2 bg-gradient-to-r from-emerald-500 to-green-600 rounded-lg">
                    <FileSpreadsheet className="h-5 w-5 text-white" />
                  </div>
                  <div>
                    <CardTitle className="text-lg text-gray-900">รายการผู้ใช้</CardTitle>
                    <CardDescription>จัดการและติดตามข้อมูลผู้ใช้</CardDescription>
                  </div>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <Tabs defaultValue="users" className="w-full">
                <TabsList className="grid w-full grid-cols-2">
                  <TabsTrigger value="users">ข้อมูลผู้ใช้</TabsTrigger>
                  <TabsTrigger value="download">Download Features</TabsTrigger>
                </TabsList>
                
                <TabsContent value="users" className="space-y-4">
                  {/* Sample user cards */}
                  <div className="space-y-3">
                    {[
                      {
                        name: "นายตัวอย่าง ใช้งาน",
                        id: "1234567890123",
                        phone: "0812345678",
                        age: 30,
                        techLevel: "intermediate",
                        status: "ปานกลาง"
                      },
                      {
                        name: "นางสาวตัวอย่าง ทดสอบ",
                        id: "9876543210987",
                        phone: "0898765432",
                        age: 25,
                        techLevel: "beginner",
                        status: "ไม่เก่งเทคโนโลยี"
                      }
                    ].map((user, index) => (
                      <div key={index} className="p-4 border rounded-lg bg-white shadow-sm">
                        <div className="flex items-center justify-between mb-2">
                          <div className="flex items-center space-x-2">
                            <h3 className="font-medium text-gray-900">{user.name}</h3>
                            <Badge 
                              variant={user.techLevel === 'beginner' ? 'destructive' : 'secondary'}
                              className={user.techLevel === 'beginner' ? 'bg-red-100 text-red-700' : 'bg-orange-100 text-orange-700'}
                            >
                              {user.status}
                            </Badge>
                          </div>
                        </div>
                        <div className="text-sm text-gray-600 space-y-1">
                          <p>บัตรประชาชน: {user.id}</p>
                          <p>เบอร์: {user.phone} | อายุ: {user.age} ปี</p>
                        </div>
                        {user.techLevel === 'beginner' && (
                          <div className="mt-2 p-2 bg-red-50 rounded border border-red-200">
                            <div className="flex items-center space-x-2">
                              <AlertCircle className="h-4 w-4 text-red-600" />
                              <span className="text-xs text-red-700 font-medium">
                                ต้องการการดูแลพิเศษจาก อสม. - แนะนำการเยี่ยมบ้าน
                              </span>
                            </div>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </TabsContent>

                <TabsContent value="download" className="space-y-4">
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                    {/* Download Current Data */}
                    <Card className="border-emerald-200 bg-emerald-50">
                      <CardHeader className="pb-3">
                        <div className="flex items-center space-x-2">
                          <Download className="h-5 w-5 text-emerald-600" />
                          <CardTitle className="text-base text-emerald-800">ดาวน์โหลดข้อมูลปัจจุบัน</CardTitle>
                        </div>
                      </CardHeader>
                      <CardContent>
                        <p className="text-sm text-emerald-700 mb-3">
                          ดาวน์โหลดข้อมูลผู้ใช้ทั้งหมดที่มีในระบบปัจจุบัน พร้อม Header สีและจัดรูปแบบ
                        </p>
                        <Button
                          onClick={() => handleDownload('data')}
                          disabled={isDownloading}
                          className="w-full bg-emerald-600 hover:bg-emerald-700"
                        >
                          {isDownloading ? 'กำลังดาวน์โหลด...' : 'ดาวน์โหลดข้อมูล'}
                        </Button>
                      </CardContent>
                    </Card>

                    {/* Download Empty Template */}
                    <Card className="border-blue-200 bg-blue-50">
                      <CardHeader className="pb-3">
                        <div className="flex items-center space-x-2">
                          <FileDown className="h-5 w-5 text-blue-600" />
                          <CardTitle className="text-base text-blue-800">ดาวน์โหลด Template ว่าง</CardTitle>
                        </div>
                      </CardHeader>
                      <CardContent>
                        <p className="text-sm text-blue-700 mb-3">
                          ดาวน์โหลด Excel Template พร้อมตัวอย่างข้อมูลและคำแนะนำการใช้งาน
                        </p>
                        <Button
                          onClick={() => handleDownload('template')}
                          disabled={isDownloading}
                          variant="outline"
                          className="w-full border-blue-500 text-blue-600 hover:bg-blue-100"
                        >
                          {isDownloading ? 'กำลังดาวน์โหลด...' : 'ดาวน์โหลด Template'}
                        </Button>
                      </CardContent>
                    </Card>
                  </div>

                  {/* Features List */}
                  <Card className="bg-gray-50 border-gray-200">
                    <CardHeader className="pb-3">
                      <CardTitle className="text-base text-gray-800">ฟีเจอร์การ Download</CardTitle>
                    </CardHeader>
                    <CardContent>
                      <div className="space-y-2">
                        <div className="flex items-center space-x-2 text-sm">
                          <CheckCircle className="h-4 w-4 text-green-600" />
                          <span>Header สีเขียว เพื่อให้เห็นชัดเจน</span>
                        </div>
                        <div className="flex items-center space-x-2 text-sm">
                          <CheckCircle className="h-4 w-4 text-green-600" />
                          <span>ปรับความกว้างคอลัมน์อัตโนมัติ</span>
                        </div>
                        <div className="flex items-center space-x-2 text-sm">
                          <CheckCircle className="h-4 w-4 text-green-600" />
                          <span>Sheet คำอธิบายแยกต่างหาก</span>
                        </div>
                        <div className="flex items-center space-x-2 text-sm">
                          <CheckCircle className="h-4 w-4 text-green-600" />
                          <span>รองรับทุกแพลตฟอร์ม (Mobile/Desktop)</span>
                        </div>
                        <div className="flex items-center space-x-2 text-sm">
                          <CheckCircle className="h-4 w-4 text-green-600" />
                          <span>ข้อมูลตัวอย่างและคำแนะนำ</span>
                        </div>
                      </div>
                    </CardContent>
                  </Card>
                </TabsContent>
              </Tabs>
            </CardContent>
          </Card>
        </div>

        {/* Excel Template Structure */}
        <Card className="mt-8 shadow-xl border-0 bg-white/70 backdrop-blur">
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <FileSpreadsheet className="h-5 w-5 text-emerald-600" />
              <span>โครงสร้างไฟล์ Excel Template</span>
            </CardTitle>
            <CardDescription>
              คอลัมน์และรูปแบบข้อมูลที่รองรับ
            </CardDescription>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h4 className="font-medium text-red-700 mb-2">คอลัมน์ที่จำเป็น (ต้องมี)</h4>
                <ul className="space-y-1 text-sm">
                  <li className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                    <span><strong>เลขบัตรประจำตัวประชาชน</strong> - เลข 13 หลัก</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                    <span><strong>ชื่อ-นามสกุล</strong> - ชื่อและนามสกุลเต็ม</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                    <span><strong>เบอร์โทร</strong> - เลข 10 หลัก (เช่น 0812345678)</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-red-500 rounded-full"></div>
                    <span><strong>อายุ</strong> - ตัวเลขเท่านั้น</span>
                  </li>
                </ul>
              </div>
              <div>
                <h4 className="font-medium text-blue-700 mb-2">คอลัมน์เสริม (ไม่บังคับ)</h4>
                <ul className="space-y-1 text-sm">
                  <li className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                    <span>ที่อยู่, เพศ, น้ำหนัก, ส่วนสูง</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                    <span>โรคประจำตัว, หมู่บ้าน, ตำบล</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                    <span>อำเภอ, จังหวัด</span>
                  </li>
                  <li className="flex items-center space-x-2">
                    <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                    <span><strong>ความเก่งเทคโนโลยี</strong> - ไม่เก่ง, ปานกลาง, เก่งเทคโนโลยี</span>
                  </li>
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  )
}