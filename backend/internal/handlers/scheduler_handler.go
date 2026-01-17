package handlers

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/truthordare/backend/internal/models"
	"github.com/truthordare/backend/internal/scheduler"
)

// SchedulerHandler handles scheduler-related API requests.
type SchedulerHandler struct {
	scheduler *scheduler.Scheduler
}

// NewSchedulerHandler creates a new SchedulerHandler.
func NewSchedulerHandler(sched *scheduler.Scheduler) *SchedulerHandler {
	return &SchedulerHandler{
		scheduler: sched,
	}
}

// GetJobs godoc
// @Summary Get all scheduled jobs
// @Description Returns information about all registered scheduler jobs including next/previous run times
// @Tags scheduler
// @Produce json
// @Success 200 {object} SchedulerJobsResponse
// @Router /scheduler/jobs [get]
func (h *SchedulerHandler) GetJobs(c *gin.Context) {
	jobs := h.scheduler.GetJobs()

	c.JSON(http.StatusOK, SchedulerJobsResponse{
		Jobs: jobs,
	})
}

// RunJobRequest is the request body for running a job manually.
type RunJobRequest struct {
	JobName string `json:"job_name" binding:"required"`
}

// RunJob godoc
// @Summary Run a job manually
// @Description Triggers a scheduled job to run immediately
// @Tags scheduler
// @Accept json
// @Produce json
// @Param request body RunJobRequest true "Job name to run"
// @Success 200 {object} RunJobResponse
// @Failure 400 {object} models.ErrorResponse
// @Failure 500 {object} models.ErrorResponse
// @Router /scheduler/run [post]
func (h *SchedulerHandler) RunJob(c *gin.Context) {
	var req RunJobRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, models.ErrorResponse{
			Error:   "validation_error",
			Message: err.Error(),
		})
		return
	}

	err := h.scheduler.RunJobNow(req.JobName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, models.ErrorResponse{
			Error:   "job_error",
			Message: err.Error(),
		})
		return
	}

	c.JSON(http.StatusOK, RunJobResponse{
		Success: true,
		Message: "Job triggered successfully",
		JobName: req.JobName,
	})
}

// SchedulerJobsResponse is the response for the GetJobs endpoint.
type SchedulerJobsResponse struct {
	Jobs []scheduler.JobInfo `json:"jobs"`
}

// RunJobResponse is the response for the RunJob endpoint.
type RunJobResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	JobName string `json:"job_name"`
}
