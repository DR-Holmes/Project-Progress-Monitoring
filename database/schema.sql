USE [master]
GO

CREATE DATABASE [FypProjectProgDB]
GO

ALTER DATABASE [FypProjectProgDB] SET COMPATIBILITY_LEVEL = 160
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [FypProjectProgDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [FypProjectProgDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [FypProjectProgDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [FypProjectProgDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [FypProjectProgDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET  ENABLE_BROKER 
GO
ALTER DATABASE [FypProjectProgDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [FypProjectProgDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [FypProjectProgDB] SET  MULTI_USER 
GO
ALTER DATABASE [FypProjectProgDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [FypProjectProgDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [FypProjectProgDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [FypProjectProgDB] SET TARGET_RECOVERY_TIME = 60 SECONDS 
GO
ALTER DATABASE [FypProjectProgDB] SET DELAYED_DURABILITY = DISABLED 
GO
ALTER DATABASE [FypProjectProgDB] SET ACCELERATED_DATABASE_RECOVERY = OFF  
GO
ALTER DATABASE [FypProjectProgDB] SET QUERY_STORE = ON
GO
ALTER DATABASE [FypProjectProgDB] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 30), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 60, MAX_STORAGE_SIZE_MB = 1000, QUERY_CAPTURE_MODE = AUTO, SIZE_BASED_CLEANUP_MODE = AUTO, MAX_PLANS_PER_QUERY = 200, WAIT_STATS_CAPTURE_MODE = ON)
GO
USE [FypProjectProgDB]
GO
/****** Object:  Table [dbo].[ComiteeMeeting]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ComiteeMeeting](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[meetingDescription] [varchar](200) NULL,
	[startDate] [date] NULL,
	[endDate] [date] NULL,
	[startTime] [time](7) NULL,
	[endTime] [time](7) NULL,
	[venue] [varchar](50) NULL,
	[selectedDays] [varchar](100) NULL,
	[sessionID] [int] NULL,
	[isGraded] [bit] NULL,
	[isFileRequired] [bit] NULL,
	[title] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Department]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Department](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Enrollment]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Enrollment](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[studentID] [varchar](20) NULL,
	[sessionID] [int] NULL,
	[subject] [varchar](50) NULL,
	[grade] [varchar](5) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Fyp1EvaluationParameters]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fyp1EvaluationParameters](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FYP1Evaluators]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FYP1Evaluators](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[sessionEvalID] [int] NULL,
	[evaluatorID] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FYP1Score]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FYP1Score](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[evaluatorID] [varchar](20) NULL,
	[parameterID] [int] NULL,
	[sessionID] [int] NULL,
	[score] [int] NULL,
	[groupMemberID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Fyp1SessionEvaluation]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fyp1SessionEvaluation](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[sessionID] [int] NULL,
	[parameterID] [int] NULL,
	[percentage] [float] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[FYP2Score]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[FYP2Score](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[evaluatorID] [varchar](20) NULL,
	[evaluationID] [int] NULL,
	[sessionID] [int] NULL,
	[score] [int] NULL,
	[groupMemberID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Fyp2Task]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fyp2Task](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[groupID] [int] NULL,
	[sessionID] [int] NULL,
	[taskDescription] [varchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Fyp2TaskEvaluation]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Fyp2TaskEvaluation](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[taskID] [int] NULL,
	[evaluatorID] [varchar](20) NULL,
	[studentID] [varchar](20) NULL,
	[remarks] [varchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GroupMembers]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GroupMembers](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[groupID] [int] NULL,
	[studentID] [varchar](20) NULL,
	[isAdmin] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GroupRequestMembers]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GroupRequestMembers](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[RequestID] [int] NOT NULL,
	[MemberRegNum] [varchar](20) NULL,
	[Status] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GroupRequests]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GroupRequests](
	[RequestID] [int] IDENTITY(1,1) NOT NULL,
	[FromRegNum] [varchar](20) NULL,
	[SessionID] [int] NULL,
	[RequestDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[RequestID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[GroupSchedule]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[GroupSchedule](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[groupID] [int] NULL,
	[comiteeMeetingID] [int] NULL,
	[filePath] [varchar](200) NULL,
	[Status] [varchar](20) NULL,
	[estimatedTime] [time](7) NULL,
	[meetingDate] [date] NULL,
	[isAttend] [int] NULL,
	[type] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingAttendance]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MeetingAttendance](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[scheduleID] [int] NULL,
	[attendance] [bit] NULL,
	[remarks] [varchar](200) NULL,
	[studentID] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingQueue]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MeetingQueue](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[meetingDate] [date] NULL,
	[meetingTime] [time](7) NULL,
	[status] [varchar](20) NULL,
	[scheduleID] [int] NULL,
	[sessionID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[MeetingQueueAttendance]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[MeetingQueueAttendance](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[meetingQueueID] [int] NULL,
	[memberID] [int] NULL,
	[isPresent] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[OfferedProject]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[OfferedProject](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[sessionID] [int] NULL,
	[projectID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Project]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Project](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[title] [varchar](50) NULL,
	[suggestedBy] [varchar](20) NULL,
	[projectStatus] [bit] NULL,
	[objectives] [varchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[ProjectGroup]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ProjectGroup](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[createdBy] [varchar](20) NULL,
	[supervisorID] [varchar](20) NULL,
	[projectID] [int] NULL,
	[isFinalized] [int] NOT NULL,
	[createdSession] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[RecurringMeetingDays]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RecurringMeetingDays](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[meetingID] [int] NULL,
	[meetingDay] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Section]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Section](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Session]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Session](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](20) NULL,
	[startDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[StudentFypAttempts]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[StudentFypAttempts](
	[attemptId] [int] IDENTITY(1,1) NOT NULL,
	[studentId] [varchar](20) NULL,
	[sessionId] [int] NULL,
	[groupId] [int] NULL,
	[fypType] [tinyint] NULL,
	[status] [varchar](20) NULL,
	[createdAt] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[attemptId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Students]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Students](
	[regNum] [varchar](20) NOT NULL,
	[name] [varchar](50) NULL,
	[admissionSession] [int] NULL,
	[currentCGPA] [float] NULL,
	[gender] [char](1) NULL,
	[selectedTech] [int] NULL,
	[studentDepartment] [int] NULL,
	[studentSection] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[regNum] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SuperVisorAttendance]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SuperVisorAttendance](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[attendanceDate] [date] NULL,
	[meetingID] [int] NULL,
	[isAttend] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SuperVisorMeeting]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SuperVisorMeeting](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[date] [date] NULL,
	[time] [time](7) NULL,
	[day] [varchar](20) NULL,
	[venue] [varchar](50) NULL,
	[createdBy] [varchar](20) NULL,
	[groupID] [int] NULL,
	[isRecurring] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SupNotBroadCast]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SupNotBroadCast](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[studentID] [varchar](20) NULL,
	[meetingID] [int] NULL,
	[notStatus] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[SupTaskBroadCast]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[SupTaskBroadCast](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[studentID] [varchar](20) NULL,
	[taskID] [int] NULL,
	[notStatus] [bit] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[TaskEvaluation]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[TaskEvaluation](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[taskID] [int] NULL,
	[taskRemarks] [varchar](200) NULL,
	[submissionFilePath] [varchar](200) NULL,
	[submissionDate] [date] NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Tasks]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Tasks](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[title] [varchar](50) NULL,
	[taskDescription] [varchar](500) NULL,
	[assignDate] [date] NULL,
	[dueDate] [date] NULL,
	[assignedBy] [varchar](20) NULL,
	[groupID] [int] NULL,
	[studentID] [varchar](20) NULL,
	[isPptRequired] [bit] NULL,
	[taskStatus] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Technology]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Technology](
	[id] [int] IDENTITY(1,1) NOT NULL,
	[name] [varchar](50) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
/****** Object:  Table [dbo].[Users]    Script Date: 2/16/2026 10:22:33 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Users](
	[id] [varchar](20) NOT NULL,
	[name] [varchar](50) NULL,
	[password] [varchar](50) NULL,
	[email] [varchar](50) NULL,
	[role] [varchar](20) NULL,
PRIMARY KEY CLUSTERED 
(
	[id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[GroupMembers] ADD  DEFAULT ((0)) FOR [isAdmin]
GO
ALTER TABLE [dbo].[GroupRequestMembers] ADD  DEFAULT ('Pending') FOR [Status]
GO
ALTER TABLE [dbo].[GroupRequests] ADD  DEFAULT (getdate()) FOR [RequestDate]
GO
ALTER TABLE [dbo].[ProjectGroup] ADD  DEFAULT ((0)) FOR [isFinalized]
GO
ALTER TABLE [dbo].[StudentFypAttempts] ADD  DEFAULT (getdate()) FOR [createdAt]
GO
ALTER TABLE [dbo].[ComiteeMeeting]  WITH CHECK ADD FOREIGN KEY([sessionID])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[Enrollment]  WITH CHECK ADD FOREIGN KEY([sessionID])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[Enrollment]  WITH CHECK ADD FOREIGN KEY([studentID])
REFERENCES [dbo].[Students] ([regNum])
GO
ALTER TABLE [dbo].[FYP1Evaluators]  WITH CHECK ADD FOREIGN KEY([evaluatorID])
REFERENCES [dbo].[Users] ([id])
GO
ALTER TABLE [dbo].[FYP1Evaluators]  WITH CHECK ADD FOREIGN KEY([sessionEvalID])
REFERENCES [dbo].[Fyp1SessionEvaluation] ([id])
GO
ALTER TABLE [dbo].[FYP1Score]  WITH CHECK ADD FOREIGN KEY([evaluatorID])
REFERENCES [dbo].[Users] ([id])
GO
ALTER TABLE [dbo].[FYP1Score]  WITH CHECK ADD FOREIGN KEY([groupMemberID])
REFERENCES [dbo].[GroupMembers] ([id])
GO
ALTER TABLE [dbo].[FYP1Score]  WITH CHECK ADD FOREIGN KEY([parameterID])
REFERENCES [dbo].[Fyp1EvaluationParameters] ([id])
GO
ALTER TABLE [dbo].[FYP1Score]  WITH CHECK ADD FOREIGN KEY([sessionID])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[Fyp1SessionEvaluation]  WITH CHECK ADD FOREIGN KEY([parameterID])
REFERENCES [dbo].[Fyp1EvaluationParameters] ([id])
GO
ALTER TABLE [dbo].[Fyp1SessionEvaluation]  WITH CHECK ADD FOREIGN KEY([sessionID])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[FYP2Score]  WITH CHECK ADD FOREIGN KEY([evaluatorID])
REFERENCES [dbo].[Users] ([id])
GO
ALTER TABLE [dbo].[FYP2Score]  WITH CHECK ADD FOREIGN KEY([evaluationID])
REFERENCES [dbo].[Fyp2TaskEvaluation] ([id])
GO
ALTER TABLE [dbo].[FYP2Score]  WITH CHECK ADD FOREIGN KEY([groupMemberID])
REFERENCES [dbo].[GroupMembers] ([id])
GO
ALTER TABLE [dbo].[FYP2Score]  WITH CHECK ADD FOREIGN KEY([sessionID])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[Fyp2Task]  WITH CHECK ADD FOREIGN KEY([sessionID])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[Fyp2TaskEvaluation]  WITH CHECK ADD FOREIGN KEY([evaluatorID])
REFERENCES [dbo].[Users] ([id])
GO
ALTER TABLE [dbo].[Fyp2TaskEvaluation]  WITH CHECK ADD FOREIGN KEY([studentID])
REFERENCES [dbo].[Students] ([regNum])
GO
ALTER TABLE [dbo].[Fyp2TaskEvaluation]  WITH CHECK ADD FOREIGN KEY([taskID])
REFERENCES [dbo].[Fyp2Task] ([id])
GO
ALTER TABLE [dbo].[GroupMembers]  WITH CHECK ADD FOREIGN KEY([groupID])
REFERENCES [dbo].[ProjectGroup] ([id])
GO
ALTER TABLE [dbo].[GroupMembers]  WITH CHECK ADD FOREIGN KEY([studentID])
REFERENCES [dbo].[Students] ([regNum])
GO
ALTER TABLE [dbo].[GroupRequestMembers]  WITH CHECK ADD FOREIGN KEY([MemberRegNum])
REFERENCES [dbo].[Students] ([regNum])
GO
ALTER TABLE [dbo].[GroupRequestMembers]  WITH CHECK ADD FOREIGN KEY([RequestID])
REFERENCES [dbo].[GroupRequests] ([RequestID])
GO
ALTER TABLE [dbo].[GroupRequests]  WITH CHECK ADD FOREIGN KEY([FromRegNum])
REFERENCES [dbo].[Students] ([regNum])
GO
ALTER TABLE [dbo].[GroupRequests]  WITH CHECK ADD FOREIGN KEY([SessionID])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[GroupSchedule]  WITH CHECK ADD FOREIGN KEY([comiteeMeetingID])
REFERENCES [dbo].[ComiteeMeeting] ([id])
GO
ALTER TABLE [dbo].[MeetingAttendance]  WITH CHECK ADD FOREIGN KEY([scheduleID])
REFERENCES [dbo].[GroupSchedule] ([id])
GO
ALTER TABLE [dbo].[MeetingQueue]  WITH CHECK ADD FOREIGN KEY([scheduleID])
REFERENCES [dbo].[GroupSchedule] ([id])
GO
ALTER TABLE [dbo].[MeetingQueue]  WITH CHECK ADD FOREIGN KEY([sessionID])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[MeetingQueueAttendance]  WITH CHECK ADD FOREIGN KEY([meetingQueueID])
REFERENCES [dbo].[MeetingQueue] ([id])
GO
ALTER TABLE [dbo].[MeetingQueueAttendance]  WITH CHECK ADD FOREIGN KEY([memberID])
REFERENCES [dbo].[GroupMembers] ([id])
GO
ALTER TABLE [dbo].[OfferedProject]  WITH CHECK ADD FOREIGN KEY([projectID])
REFERENCES [dbo].[Project] ([id])
GO
ALTER TABLE [dbo].[OfferedProject]  WITH CHECK ADD FOREIGN KEY([sessionID])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[Project]  WITH CHECK ADD FOREIGN KEY([suggestedBy])
REFERENCES [dbo].[Users] ([id])
GO
ALTER TABLE [dbo].[ProjectGroup]  WITH CHECK ADD FOREIGN KEY([createdBy])
REFERENCES [dbo].[Users] ([id])
GO
ALTER TABLE [dbo].[ProjectGroup]  WITH CHECK ADD FOREIGN KEY([createdSession])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[ProjectGroup]  WITH CHECK ADD FOREIGN KEY([projectID])
REFERENCES [dbo].[OfferedProject] ([id])
GO
ALTER TABLE [dbo].[ProjectGroup]  WITH CHECK ADD FOREIGN KEY([supervisorID])
REFERENCES [dbo].[Users] ([id])
GO
ALTER TABLE [dbo].[RecurringMeetingDays]  WITH CHECK ADD FOREIGN KEY([meetingID])
REFERENCES [dbo].[SuperVisorMeeting] ([id])
GO
ALTER TABLE [dbo].[StudentFypAttempts]  WITH CHECK ADD FOREIGN KEY([sessionId])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[StudentFypAttempts]  WITH CHECK ADD FOREIGN KEY([studentId])
REFERENCES [dbo].[Students] ([regNum])
GO
ALTER TABLE [dbo].[Students]  WITH CHECK ADD FOREIGN KEY([admissionSession])
REFERENCES [dbo].[Session] ([id])
GO
ALTER TABLE [dbo].[Students]  WITH CHECK ADD FOREIGN KEY([regNum])
REFERENCES [dbo].[Users] ([id])
GO
ALTER TABLE [dbo].[Students]  WITH CHECK ADD FOREIGN KEY([selectedTech])
REFERENCES [dbo].[Technology] ([id])
GO
ALTER TABLE [dbo].[Students]  WITH CHECK ADD FOREIGN KEY([studentDepartment])
REFERENCES [dbo].[Department] ([id])
GO
ALTER TABLE [dbo].[Students]  WITH CHECK ADD FOREIGN KEY([studentSection])
REFERENCES [dbo].[Section] ([id])
GO
ALTER TABLE [dbo].[SuperVisorAttendance]  WITH CHECK ADD FOREIGN KEY([meetingID])
REFERENCES [dbo].[SuperVisorMeeting] ([id])
GO
ALTER TABLE [dbo].[SuperVisorMeeting]  WITH CHECK ADD FOREIGN KEY([createdBy])
REFERENCES [dbo].[Users] ([id])
GO
ALTER TABLE [dbo].[SupNotBroadCast]  WITH CHECK ADD FOREIGN KEY([meetingID])
REFERENCES [dbo].[SuperVisorMeeting] ([id])
GO
ALTER TABLE [dbo].[SupNotBroadCast]  WITH CHECK ADD FOREIGN KEY([studentID])
REFERENCES [dbo].[Students] ([regNum])
GO
ALTER TABLE [dbo].[SupTaskBroadCast]  WITH CHECK ADD FOREIGN KEY([studentID])
REFERENCES [dbo].[Students] ([regNum])
GO
ALTER TABLE [dbo].[SupTaskBroadCast]  WITH CHECK ADD FOREIGN KEY([taskID])
REFERENCES [dbo].[Tasks] ([id])
GO
ALTER TABLE [dbo].[TaskEvaluation]  WITH CHECK ADD FOREIGN KEY([taskID])
REFERENCES [dbo].[Tasks] ([id])
GO
ALTER TABLE [dbo].[Tasks]  WITH CHECK ADD FOREIGN KEY([assignedBy])
REFERENCES [dbo].[Users] ([id])
GO
ALTER TABLE [dbo].[Tasks]  WITH CHECK ADD FOREIGN KEY([studentID])
REFERENCES [dbo].[Students] ([regNum])
GO
USE [master]
GO
ALTER DATABASE [FypProjectProgDB] SET  READ_WRITE 
GO

USE [FypProjectProgDB];
GO

ALTER TABLE [dbo].[SuperVisorMeeting]
ADD 
    [title] VARCHAR(255) NULL,
    [description] VARCHAR(MAX) NULL,
    [endTime] TIME(7) NULL,
    [groupMemberID] INT NULL;
GO

ALTER TABLE [dbo].[SuperVisorMeeting]
ADD CONSTRAINT FK_SuperVisorMeeting_GroupMembers 
FOREIGN KEY ([groupMemberID]) REFERENCES [dbo].[GroupMembers]([id]);
GO

USE [FypProjectProgDB];
GO

ALTER TABLE [dbo].[SuperVisorAttendance]
ADD [studentID] VARCHAR(20) NULL;
GO

ALTER TABLE [dbo].[SuperVisorAttendance]
ADD CONSTRAINT FK_SupAtt_Student 
FOREIGN KEY ([studentID]) REFERENCES [dbo].[Students]([regNum]);
GO

drop table FYP1Evaluators
drop table FYP1Score
drop table  Fyp1SessionEvaluation
drop table Fyp1EvaluationParameters 

USE [FypProjectProgDB];
GO

-- Cleanup existing tables before recreation
IF OBJECT_ID('[dbo].[Fyp1ParameterEvaluator]', 'U') IS NOT NULL DROP TABLE [dbo].[Fyp1ParameterEvaluator];
IF OBJECT_ID('[dbo].[Fyp1SubParameter]', 'U') IS NOT NULL DROP TABLE [dbo].[Fyp1SubParameter];
IF OBJECT_ID('[dbo].[Fyp1EvaluationParameters]', 'U') IS NOT NULL DROP TABLE [dbo].[Fyp1EvaluationParameters];
GO

-- 1. Main Parameters Table
CREATE TABLE [dbo].[Fyp1EvaluationParameters] (
    [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [name] NVARCHAR(200) NULL,
    [percentage] INT NULL,
    [sessionID] INT NULL,
    [allowEvaluation] BIT NULL,
    CONSTRAINT FK_Fyp1Eval_Session FOREIGN KEY ([sessionID]) REFERENCES [dbo].[Session]([id])
); -- [cite: 16, 32]

-- 2. Sub-Parameters Table 
CREATE TABLE [dbo].[Fyp1SubParameter] (
    [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [parameterID] INT NULL,
    [name] NVARCHAR(200) NULL,
    [percentage] INT NULL,
    CONSTRAINT FK_Fyp1Sub_Param FOREIGN KEY ([parameterID]) REFERENCES [dbo].[Fyp1EvaluationParameters]([id])
); -- [cite: 33]

-- 3. Parameter Evaluator Mapping Table
CREATE TABLE [dbo].[Fyp1ParameterEvaluator] (
    [id] INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
    [parameterID] INT NULL,
    -- evaluatorID type VARCHAR(20) matches the Users table primary key
    [evaluatorID] VARCHAR(20) NULL, 
    CONSTRAINT FK_Fyp1ParaEval_Param FOREIGN KEY ([parameterID]) REFERENCES [dbo].[Fyp1EvaluationParameters]([id]),
    CONSTRAINT FK_Fyp1ParaEval_User FOREIGN KEY ([evaluatorID]) REFERENCES [dbo].[Users]([id])
); -- [cite: 22, 34]
GO
-- Add Reminder support to Meetings
ALTER TABLE [dbo].[SuperVisorMeeting] 
ADD [isReminderSet] BIT DEFAULT 0;

-- Add Progress Tracking and Reminder support to Tasks
ALTER TABLE [dbo].[Tasks] 
ADD [completionPercentage] INT DEFAULT 0,
    [isReminderSet] BIT DEFAULT 0;


-- Add Meeting Notes support
ALTER TABLE [dbo].[SuperVisorMeeting] 
ADD [meetingNotes] VARCHAR(MAX);

-- Add individual task remarks (for progress updates)
ALTER TABLE [dbo].[Tasks] 
ADD [remarks] VARCHAR(500);


-- For Meeting Notes
ALTER TABLE [dbo].[SuperVisorMeeting] ADD [meetingNotes] VARCHAR(MAX);

-- For Individual Task Progress Tracking without duplicating Tasks
CREATE TABLE [dbo].[StudentTaskProgress] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [taskID] INT,
    [studentID] VARCHAR(20),
    [completionPercentage] INT DEFAULT 0,
    [taskStatus] VARCHAR(20) DEFAULT 'Pending',
    [remarks] VARCHAR(500),
    CONSTRAINT FK_TaskProgress_Task FOREIGN KEY ([taskID]) REFERENCES [dbo].[Tasks]([id]),
    CONSTRAINT FK_TaskProgress_Student FOREIGN KEY ([studentID]) REFERENCES [dbo].[Students]([regNum])
);

