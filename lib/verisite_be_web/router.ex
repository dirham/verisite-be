defmodule VerisiteBeWeb.Router do
  use VerisiteBeWeb, :router

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :authenticated_api do
    plug(:accepts, ["json"])
    plug(VerisiteBeWeb.Plugs.AuthenticateBearer)
  end

  scope "/api", VerisiteBeWeb do
    pipe_through(:api)

    get("/health", HealthController, :show)
    post("/auth/login", AuthController, :login)
  end

  scope "/api", VerisiteBeWeb do
    pipe_through(:authenticated_api)

    get("/profile", ProfileController, :show)
    patch("/profile", ProfileController, :update)
    post("/profile/photo", ProfileController, :update_photo)
    put("/profile/language", ProfileController, :update_language)
    post("/profile/logout", ProfileController, :logout)
    post("/files/upload", FileController, :create)
    post("/attendance/clock-in", AttendanceController, :clock_in)
    post("/attendance/clock-out", AttendanceController, :clock_out)
    post("/attendance/location-samples", AttendanceController, :location_samples)
    get("/attendance/history", AttendanceController, :history)
    get("/reports/attendance/insights", ReportController, :attendance_insights)
    get("/reports/attendance/export", ReportController, :export_attendance)
    get("/reports/reimbursements/summary", ReportController, :reimbursement_summary)
    get("/reports/reimbursements/export", ReportController, :export_reimbursements)
    get("/reimbursements", ReimbursementController, :index)
    post("/reimbursements", ReimbursementController, :create)
    post("/reimbursements/:requestId/cancel", ReimbursementController, :cancel)
    post("/admin/reimbursements/:requestId/approve", ReimbursementController, :approve)
    post("/admin/reimbursements/:requestId/reject", ReimbursementController, :reject)
    post("/admin/reimbursements/:requestId/payment", ReimbursementController, :payment)
    get("/admin/settings/storage", FileController, :settings)
    put("/admin/settings/storage", FileController, :update_settings)
  end
end
