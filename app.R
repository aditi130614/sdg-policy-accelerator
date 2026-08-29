# =========================================================
# Six Transformations Accelerator – SDG Policy Simulator
# =========================================================

library(shiny)
library(shinydashboard)
library(plotly)
library(dplyr)
library(shinyalert)
library(jsonlite)

# ---------------------------------------------------------
# Load prepared data (with ISO3 already added)
# ---------------------------------------------------------
sdg_df <- readRDS("sdg_prepared.rds")
cor_weights <- readRDS("correlation_groups.rds")

# ---------------------------------------------------------
# Core cascade logic
# ---------------------------------------------------------
apply_boost_and_cascade <- function(
    current_scores,
    focus,
    boost_pct,
    cor_weights,
    overdrive = FALSE
) {
  boost_factor <- boost_pct / 100
  if (overdrive) boost_factor <- boost_factor * 1.5
  
  boosted <- current_scores
  
  boosted[focus] <- boosted[focus] +
    boost_factor * (100 - boosted[focus])
  
  for (tr in names(current_scores)) {
    if (tr != focus) {
      spill <- cor_weights[focus, tr]
      boosted[tr] <- boosted[tr] +
        spill * boost_factor * (100 - boosted[tr])
    }
  }
  
  pmin(boosted, 100)
}

# ---------------------------------------------------------
# UI
# ---------------------------------------------------------
ui <- dashboardPage(
  
  dashboardHeader(
    title = "Six Pillar Transformations"
  ),
  
  dashboardSidebar(
    width = 300,
    
    tags$div(
      "SDG Accelerator Controls",
      style = "font-size:18px;font-weight:700;color:#6B4E3D;margin-bottom:12px;"
    ),
    
    selectInput(
      "country", "Country / Region",
      choices = sort(unique(sdg_df$Country)),
      selected = sort(unique(sdg_df$Country))[1]
    ),
    
    selectInput(
      "focus", "Transformation to Accelerate",
      choices = c("Food","Energy","Digital","Education","Jobs","Climate"),
      selected = "Energy"
    ),
    
    sliderInput(
      "boost", "Policy Acceleration Level (%)",
      min = 0, max = 100, value = 30, step = 5
    ),
    tags$div(
      style = "margin-top:6px; text-align:center;",
      actionLink(
        "policy_info",
        label = tagList(icon("info-circle"), " What does Policy Acceleration mean?"),
        style = "color:#5A6F7A; font-size:12px;"
      )
    ),
    checkboxInput(
      "show_transformations",
      "Show individual transformation trends",
      value = FALSE
    ),
    
    actionButton(
      "overdrive",
      "Activate Overdrive Mode",
      icon = icon("rocket"),
      class = "btn-warning btn-block"
    ),
    uiOutput("overdrive_badge"),
    uiOutput("boost_feedback"),
    tags$div(
      style = "margin-top:6px; text-align:center;",
      actionLink(
        "overdrive_info",
        label = tagList(icon("info-circle"), " What does Overdrive do?"),
        style = "color:#6B4E3D; font-size:12px;"
      )
    ),
    br(),
    
    actionButton(
      "open_map",
      "View Global Comparison",
      icon = icon("globe"),
      class = "btn-default btn-block"
    ),
    
    br(),
    
    actionButton(
      "about_btn",
      "About this Dashboard",
      icon = icon("info-circle"),
      class = "btn-default btn-block"
    ),
    
    br(),
    
    actionButton(
      "coverage_btn",
      "Why only selected countries?",
      icon = icon("question-circle"),
      class = "btn-default btn-block"
    ),
    
    br(),
    
    tags$small(
      "Data: UN SDG Tier I indicators, 2015–2023",
      style = "color:#7A6F68;"
    )
  ),
  
  
  dashboardBody(
    
    useShinyalert(),
    tags$script(HTML("
  Shiny.addCustomMessageHandler('overdrivePulse', function(x) {
    $('.btn-warning').addClass('overdrive-active');
  });
")),
    
    
    
    # ---------- Pastel Theme ----------
    tags$head(tags$style(HTML("
/* =====================================
   CLEAN POLICY DASHBOARD THEME
   ===================================== */

body {
  background-color: #F4F2EE; /* warm neutral */
  font-family: 'Segoe UI', 'Helvetica Neue', sans-serif;
  color: #2B2B2B;
}

/* ---------- TOP HEADER (FIXED PROPORTION) ---------- */
.skin-blue .main-header .logo,
.skin-blue .main-header .navbar {
  background-color: #1F3D3A;   /* muted deep teal */
  color: #F6F5F3;
  font-weight: 600;
  height: 48px;                /* 🔧 NOT bulky */
  line-height: 48px;
  padding: 0 16px;
}

/* Reduce logo size */
.skin-blue .main-header .logo {
  font-size: 18px;
}

/* ---------- SIDEBAR ---------- */
.skin-blue .main-sidebar {
  background-color: #EAD8D4; /* soft clay */
}

.skin-blue .sidebar,
.skin-blue .sidebar * {
  color: #2B2B2B !important;
  font-size: 14px;
}

/* Sidebar headings */
.skin-blue .sidebar .control-label {
  font-weight: 600;
}

/* Sidebar buttons */
.skin-blue .sidebar .btn,
.skin-blue .sidebar .action-button {
  background-color: #FFFFFF;
  color: #2B2B2B;
  border-radius: 12px;
  border: 1px solid rgba(0,0,0,0.08);
  font-weight: 600;
}

/* Primary action (Overdrive) */
.btn-warning {
  background-color: #3E5F58; /* dark sage */
  color: #FFFFFF;
  border: none;
}

/* ---------- MAIN CONTENT BOXES ---------- */
.box {
  background-color: #FBFAF8;
  border-radius: 16px;
  border: 1px solid rgba(0,0,0,0.06);
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}

/* ---------- BOX HEADERS (CONSISTENT) ---------- */
.skin-blue .box > .box-header {
  background-color: #F0ECE6; /* light neutral */
  color: #2B2B2B;
  font-weight: 600;
  border-radius: 16px 16px 0 0;
  padding: 10px 14px;
}

/* Section emphasis (very subtle) */
.box-primary > .box-header {
  border-left: 6px solid #1F3D3A;
}

.box-warning > .box-header {
  border-left: 6px solid #C07A5A; /* soft terracotta */
}

.box-info > .box-header {
  border-left: 6px solid #6C8F86; /* muted green */
}

/* ---------- COLLAPSIBLE (+) ICON FIX ---------- */
.box .box-header .box-tools .btn {
  background-color: #1F3D3A;
  color: #FFFFFF !important;
  border-radius: 50%;
  width: 24px;
  height: 24px;
  line-height: 24px;
  padding: 0;
}

.box .box-header .box-tools .btn:hover {
  background-color: #C07A5A;
}

/* ---------- SLIDER ---------- */
.irs-bar {
  background-color: #C07A5A;
}

/* ---------- OVERDRIVE PULSE (VERY SUBTLE) ---------- */
@keyframes pulse-soft {
  0%   { box-shadow: 0 0 0 0 rgba(192,122,90,0.3); }
  70%  { box-shadow: 0 0 0 10px rgba(192,122,90,0); }
  100% { box-shadow: 0 0 0 0 rgba(192,122,90,0); }
}

.overdrive-active {
  animation: pulse-soft 2s infinite;
}

/* ---------- HUD BADGE ---------- */
.hud-badge {
  background-color: #F0ECE6;
  color: #2B2B2B;
  border-radius: 10px;
  font-weight: 600;
}
/* ---------- SIDEBAR WIDTH & OVERFLOW FIX ---------- */

/* Ensure sidebar never overflows */
.skin-blue .main-sidebar {
  overflow-x: hidden;
}

/* Force all sidebar controls to fit properly */
.skin-blue .sidebar .form-group,
.skin-blue .sidebar .action-button,
.skin-blue .sidebar .btn,
.skin-blue .sidebar .checkbox,
.skin-blue .sidebar .selectize-control {
  width: 100%;
  box-sizing: border-box;
}

/* Fix action buttons spilling out */
.skin-blue .sidebar .btn {
  margin-left: 0 !important;
  margin-right: 0 !important;
}

/* Reduce excessive rounding that causes overflow */
.skin-blue .sidebar .btn,
.skin-blue .sidebar input,
.skin-blue .sidebar select {
  border-radius: 12px;
}

/* Slider container fix */
.skin-blue .sidebar .irs {
  margin-left: 0;
  margin-right: 0;
}
/* ---------- HARD SIDEBAR CONSTRAINT FIX ---------- */

/* Lock sidebar content inside */
.skin-blue .main-sidebar {
  overflow-x: hidden;
  padding-left: 12px;
  padding-right: 12px;
}

/* Remove all horizontal overflow sources */
.skin-blue .sidebar * {
  max-width: 100%;
  box-sizing: border-box;
}

/* Fix pill buttons specifically */
.skin-blue .sidebar .btn {
  width: 100% !important;
  margin: 6px 0 !important;     /* vertical spacing only */
  padding-left: 12px;
  padding-right: 12px;
  border-radius: 14px;
  box-shadow: 0 4px 10px rgba(0,0,0,0.08); /* softer shadow */
}

/* Fix checkbox + text alignment */
.skin-blue .sidebar .checkbox {
  margin-left: 0;
  margin-right: 0;
}

/* Slider container clamp */
.skin-blue .sidebar .irs,
.skin-blue .sidebar .irs-line,
.skin-blue .sidebar .irs-bar {
  margin-left: 0 !important;
  margin-right: 0 !important;
}

/* Prevent icons from pushing width */
.skin-blue .sidebar i {
  margin-right: 6px;
}
/* ---------- ALIGN actionLink WITH BUTTON PILLS ---------- */

.skin-blue .sidebar a.action-link {
  display: block;
  width: 100%;
  text-align: center;

  padding: 10px 12px;
  margin: 6px 0;

  background: #FFFFFF;
  color: #2C2C2C !important;

  border-radius: 14px;
  font-weight: 600;
  text-decoration: none !important;

  box-shadow: 0 4px 10px rgba(0,0,0,0.08);
}

/* Icon spacing consistency */
.skin-blue .sidebar a.action-link i {
  margin-right: 6px;
}

/* Hover state */
.skin-blue .sidebar a.action-link:hover {
  background: #F3F3F3;
}

/* ---------- CLEAN INFO BOX (REMOVE UGLY BLUE) ---------- */

/* Box border */
.box.box-info {
  border-top: 4px solid #4F7F8F !important;
}

/* Header background */
.skin-blue .box.box-info > .box-header {
  background: #6F9FB0 !important;
  color: #0F2F3A !important;
  font-weight: 700;
}

/* Header title text */
.skin-blue .box.box-info > .box-header .box-title {
  color: #0F2F3A !important;
}

/* + / − button container */
.skin-blue .box.box-info > .box-header .box-tools .btn {
  background: #E8F1F4 !important;
  color: #0F2F3A !important;
  border-radius: 50%;
  font-weight: 700;
}

/* Hover effect for + icon */
.skin-blue .box.box-info > .box-header .box-tools .btn:hover {
  background: #D6E6EC !important;
}
/* ===== FIX BLUE & ORANGE HEADERS ===== */

/* Radar plot header (was blue) */
.box.box-primary > .box-header {
  background: #EEF2F4 !important;   /* soft neutral */
  color: #2C3E50 !important;
  border-bottom: 1px solid #D6DEE3;
}

.box.box-primary > .box-header .box-title {
  color: #2C3E50 !important;
  font-weight: 700;
}

/* Narrative Insights header (was orange) */
.box.box-warning > .box-header {
  background: #EEF2F4 !important;   /* same as above for consistency */
  color: #2C3E50 !important;
  border-bottom: 1px solid #D6DEE3;
}

.box.box-warning > .box-header .box-title {
  color: #2C3E50 !important;
  font-weight: 700;
}

/* Optional: remove aggressive top borders */
.box-primary,
.box-warning {
  border-top: 3px solid #8FA6B2 !important;
}
/* Slider filled bar */
.irs-bar,
.irs-bar-edge {
  background: #7A9E9F !important;  /* muted teal/green */
  border: none !important;
}

/* Slider handle */
.irs-handle > i:first-child {
  background: #FFFFFF !important;
  border: 2px solid #7A9E9F !important;
}

/* Slider value bubble (30) */
.irs-single {
  background: #7A9E9F !important;
  color: #FFFFFF !important;
}

/* Min / Max labels (0, 100) */
.irs-min,
.irs-max {
  background: #D6CEC8 !important;
  color: #2C2C2C !important;
}
      /* ---------- GAME STYLE ADDITIONS ---------- */

/* Pulse animation */
@keyframes pulse {
  0%   { box-shadow: 0 0 0 0 rgba(231,111,81,0.7); }
  70%  { box-shadow: 0 0 0 14px rgba(231,111,81,0); }
  100% { box-shadow: 0 0 0 0 rgba(231,111,81,0); }
}

/* Overdrive active state */
.overdrive-active {
  animation: pulse 1.6s infinite;
}

/* HUD badge */
.hud-badge {
  margin-top: 8px;
  padding: 6px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 700;
  text-align: center;
}
      
    "))),
    fluidRow(
      box(
        width = 12,
        status = "primary",
        solidHeader = TRUE,
        title = NULL,
        tags$h2(
          "Six Pillar Transformations Accelerator – 2030 Simulator",
          style = "margin:0; font-weight:700; color:#4A3B2A;"
        ),
        tags$p(
          "Interactive SDG policy simulator for cross-sector acceleration",
          style = "color:#6B4E3D; margin-top:6px;"
        )
      )
    ),
    
    # ---------- Global Comparison Map ----------
    fluidRow(
      box(
        title = "Current vs Boosted Momentum Wheel",
        width = 12,
        status = "primary",
        solidHeader = TRUE,
        plotlyOutput("radar_plot", height = 420)
      )
    ),
    fluidRow(
      box(
        title = "Narrative Insights",
        width = 12,
        status = "warning",
        solidHeader = TRUE,
        htmlOutput("insights_text")
      )
    ),
    fluidRow(
      box(
        title = "Progress Trends & 2030 Projection",
        width = 12,
        status = "info",
        solidHeader = TRUE,
        plotlyOutput("trend_plot", height = 360),
        tags$p(
          style = "font-size:13px;color:#555;",
          "Historical trend with base and accelerated scenario projections to 2030."
        )
      )
    ),
    
   
    
    fluidRow(
      box(
        title = "Indicators Used by Transformation",
        width = 12,
        status = "info",
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = TRUE,
        
        tags$ul(
          tags$li(tags$b("Food:"), " Prevalence of undernourishment (%)"),
          tags$li(tags$b("Energy:"), " Proportion with access to electricity (%),
                  Proportion with primary reliance on clean fuels/technology (%),
                  Renewable energy share in total final consumption (%)"),
          tags$li(tags$b("Digital:"), "Proportion of population covered by at least a 4G mobile network (%)"),
          tags$li(tags$b("Education:"), " Completion rate (lower secondary) (%)"),
          tags$li(tags$b("Jobs:"), " Unemployment rate, by sex and age  (%), 
                  Proportion of youth not in education/employment/training (%),
                  Proportion of population covered by at least one social protection benefit (%)"),
          tags$li(tags$b("Climate:"), "Total greenhouse gas emissions excluding LULUCF (Mt CO2e),
                  Forest area as a proportion of total land area (%)")
        )
      )
    ),
    
    fluidRow(
      box(
        title = "Methodology & Limitations",
        width = 12,
        status = "info",
        solidHeader = TRUE,
        collapsible = TRUE,
        collapsed = TRUE,
        
        tags$ul(
          tags$li(tags$b("Data:"), "UN SDG Global Database (Tier I indicators)."),
          tags$li(tags$b("Normalization:"), "Indicators scaled to 0–100."),
          tags$li(tags$b("Spillovers:"), "Correlation-based (non-causal)."),
          tags$li(tags$b("2030 Projection:"), "Linear trend extension."),
          tags$li(tags$b("Overdrive:"), "Represents coordinated governance.")
          
        ),
        
        tags$p(
          style = "font-size:13px;color:#666;",
          "Limitations: Scenario-based, not predictive. Results depend on data availability."
        )
      )
    )
    
    
  )
)

# ---------------------------------------------------------
# SERVER
# ---------------------------------------------------------
server <- function(input, output, session) {
  
  overdrive_active <- reactiveVal(FALSE)
  output$overdrive_badge <- renderUI({
    if (overdrive_active()) {
      tags$div(
        class = "hud-badge overdrive-active",
        style = "background:#E76F51;color:white;",
        icon("bolt"), " OVERDRIVE ACTIVE"
      )
    } else {
      tags$div(
        class = "hud-badge",
        style = "background:#EEE;color:#777;",
        icon("pause"), " Normal Mode"
      )
    }
  })
  output$boost_feedback <- renderUI({
    lvl <- input$boost
    
    label <- if (lvl < 25) {
      "🟢 Low intervention"
    } else if (lvl < 50) {
      "🟡 Moderate push"
    } else if (lvl < 80) {
      "🟠 Strong acceleration"
    } else {
      "🔴 Aggressive surge"
    }
    
    tags$div(
      style = "font-size:12px;text-align:center;color:#6B4E3D;margin-top:4px;",
      label
    )
  })
  observeEvent(input$about_btn, {
    shinyalert(
      title = "About the Six Pillar Transformations Accelerator",
      text = paste(
        "This dashboard is based on the 2025 UN SDG Report’s six priority transformations.",
        "It combines key SDG indicators to show country progress over time and",
        "highlights how accelerating action in one area can create positive spillovers across others,",
        "helping evaluate pathways toward the 2030 goals.",
        "\n\nIt contrasts a base trajectory with an accelerated scenario toward 2030.",
        "\n\nThe tool is exploratory and policy-oriented, not predictive."
      ),
      type = "info"
    )
  })
  
  observeEvent(input$coverage_btn, {
    shinyalert(
      title = "Countries Rationale",
      text = paste(
        "Country coverage depends on the availability of UN SDG Tier I indicators.",
        "\n\nThis allows meaningful comparison of SDG progress across economies with diverse social, economic, and environmental conditions.",
        "transformations are excluded to avoid misleading comparisons.",
        "\n\nCountries were also chosen based on the availability of reliable and comparable SDG data,",
        "with the *World* average included as a global reference."
      ),
      type = "info"
    )
  })
  observeEvent(input$open_map, {
    
    showModal(
      modalDialog(
        title = "Global Momentum Comparison",
        size = "l",
        easyClose = TRUE,
        
        plotlyOutput("world_map", height = "500px"),
        
        footer = modalButton("Close")
      )
    )
    
  })
  observeEvent(input$policy_info, {
    shinyalert(
      title = "Policy Acceleration – Explanation",
      text = paste(
        "Policy Acceleration represents an increase in the intensity and coordination",
        "of policy action within a specific transformation area.",
        "\n\nIt does NOT represent financial investment or budget expenditure.",
        "\n\nIn this dashboard, policy acceleration reflects:",
        "\n• Faster implementation of existing policies",
        "\n• Stronger institutional coordination",
        "\n• Regulatory alignment and governance effectiveness",
        "\n• Improved delivery capacity within a sector",
        "\n\nAccelerating one transformation generates spillover effects on others,",
        "based on historical correlations between SDG indicators.",
        "\n\nResults are scenario-based and exploratory, not causal forecasts."
      ),
      type = "info",
      confirmButtonText = "Got it"
    )
  })
  observeEvent(input$boost_info, {
    shinyalert(
      title = "What does Policy Acceleration mean?",
      text = paste(
        "The Policy Acceleration level represents the intensity of coordinated action",
        "applied to a transformation.",
        "\n\nIt does NOT represent financial spending or budget amounts.",
        "\n\nInstead, it reflects:",
        "\n• Strength of policy implementation",
        "\n• Institutional and governance capacity",
        "\n• Scale and coordination of interventions",
        "\n• Speed of closing remaining SDG gaps",
        "\n\nHigher values simulate stronger, more integrated action across sectors."
      ),
      type = "info"
    )
  })
  observeEvent(input$overdrive, {
    overdrive_active(TRUE)
    
    session$sendCustomMessage("overdrivePulse", TRUE)
    
    shinyalert(
      title = "Overdrive Mode Activated",
      text = "Strong coordination amplifies cross-sector synergies.",
      type = "success"
    )
  })
  observeEvent(input$overdrive_info, {
  shinyalert(
    title = "Overdrive Mode – Explanation",
    text = paste(
      "Overdrive Mode represents a high-coordination policy scenario.",
      "\n\nIn this mode, governments simultaneously align investments, regulations,",
      "and institutions across sectors (energy, food, education, jobs, digital, climate).",
      "\n\nIn the model, Overdrive increases cross-sector spillover effects,",
      "simulating stronger synergies than in a standard investment scenario.",
      "\n\nThis is a scenario-based assumption, not a forecast."
    ),
    type = "info"
  )
})
  # -------- Cascading Wheel Click Logic --------
  observeEvent(event_data("plotly_click", source = "radar_click"), {
    click <- event_data("plotly_click", source = "radar_click")
    
    if (!is.null(click$theta)) {
      updateSelectInput(
        session,
        "focus",
        selected = click$theta
      )
    }
  })
  
  observeEvent(c(input$boost, input$focus), {
    overdrive_active(FALSE)
  })
  
  country_data <- reactive({
    sdg_df %>%
      filter(Country == input$country) %>%
      arrange(Year)
  })
  
  latest_values <- reactive({
    sapply(c("Food","Energy","Digital","Education","Jobs","Climate"), function(v) {
      tmp <- country_data() %>% filter(!is.na(.data[[v]]))
      if (nrow(tmp) == 0) NA else tail(tmp[[v]], 1)
    })
  })
    # ---- Radar year tracking ----
  radar_years <- reactive({
    sapply(c("Food","Energy","Digital","Education","Jobs","Climate"), function(v) {
      tmp <- country_data() %>% filter(!is.na(.data[[v]]))
      if (nrow(tmp) == 0) NA else tail(tmp$Year, 1)
    
  })
  })
  
  # -------- Global Map --------
  output$world_map <- renderPlotly({
    
    latest_map <- sdg_df %>%
      filter(!is.na(Overall_Momentum)) %>%
      group_by(Country, ISO3) %>%
      slice_tail(n = 1) %>%
      ungroup()
    
    plot_ly(
      latest_map,
      type = "choropleth",
      locations = ~ISO3,
      z = ~Overall_Momentum,
      text = ~paste(Country, "<br>Momentum:", round(Overall_Momentum,1)),
      colorscale = list(
        c(0, "#B11226"),   # deep red
        c(0.5, "#F4D03F"), # yellow
        c(1, "#1E8449")    # dark green
      
      ),
      zmin = 0,
      zmax = 100,
      marker = list(line = list(color = "#FFFFFF", width = 0.3))
    ) %>%
      layout(
        geo = list(
          showframe = TRUE,                 # 🌍 world outline
          framecolor = "#999999",
          framewidth = 1,
          
          showcoastlines = TRUE,             # 🌊 coastlines
          coastlinecolor = "#666666",
          coastlinewidth = 0.6,
          
          showcountries = TRUE,              # 🗺 country borders
          countrycolor = "#AAAAAA",
          countrywidth = 0.5,
          
          projection = list(type = "natural earth"),
          bgcolor = "#F7F3EE"
        )
      )
  })
  
  # -------- Radar --------
  output$radar_plot <- renderPlotly({
    
    current <- latest_values()
    boosted <- apply_boost_and_cascade(
      current, input$focus, input$boost,
      cor_weights, overdrive_active()
    )
    
    labs <- names(current)
    
    p <- plot_ly(type = "scatterpolar", source = "radar_click")  %>%
      add_trace(
        r = c(current, current[1]),
        theta = c(labs, labs[1]),
        fill = "toself",
        name = "Current",
        fillcolor = "rgba(127,179,166,0.3)",
        line = list(color = "#5E8F83", dash = "dot")
      ) %>%
      add_trace(
        r = c(boosted, boosted[1]),
        theta = c(labs, labs[1]),
        fill = "toself",
        name = "Boosted",
        fillcolor = if (overdrive_active())
          "rgba(231,111,81,0.65)" else "rgba(42,157,143,0.6)",
        line = list(
          width = ifelse(labs == input$focus, 5, 2)
        )
      ) %>%
      layout(
        polar = list(radialaxis = list(range = c(0,100))),
        margin = list(b = 60),
        annotations = list(
          list(
            text = paste0(
              "Radar chart uses latest available year per transformation:<br>",
              paste(
                names(radar_years()),
                radar_years(),
                sep = ": ",
                collapse = " | "
              )
            ),
            x = 0.5,
            y = -0.15,
            xref = "paper",
            yref = "paper",
            showarrow = FALSE,
            align = "center",
            font = list(size = 11, color = "#555")
          )
        )
        
        
      )
    p <- p %>% event_register("plotly_click")
    p })
  
  # -------- Trends --------
  output$trend_plot <- renderPlotly({
    
    dfc <- country_data()
    
    hist <- dfc %>%
      filter(!is.na(Overall_Momentum)) %>%
      select(Year, Overall_Momentum)
    
    req(nrow(hist) >= 2)
    
    base_fit <- lm(Overall_Momentum ~ Year, data = hist)
    years_full <- data.frame(Year = seq(min(hist$Year), 2030))
    base_pred <- predict(base_fit, newdata = years_full)
    
    base_df <- data.frame(Year = years_full$Year, Momentum = base_pred)
    
    accel_scores <- apply_boost_and_cascade(
      latest_values(), input$focus, input$boost,
      cor_weights, overdrive_active()
    )
    
    accel_2030 <- mean(accel_scores, na.rm = TRUE)
    accel_df <- base_df
    accel_df$Momentum[accel_df$Year == 2030] <- accel_2030
    
    p <- plot_ly()
    
    if (input$show_transformations) {
      for (tr in c("Food","Energy","Digital","Education","Jobs","Climate")) {
        p <- p %>% add_lines(
          data = dfc,
          x = ~Year,
          y = as.formula(paste0("~", tr)),
          name = tr,
          line = list(width = 1),
          opacity = 0.35
        )
      }
    }
    
    p %>%
      add_lines(
        data = hist, x = ~Year, y = ~Overall_Momentum,
        name = "Historical",
        line = list(color = "#6C757D", width = 3)
      ) %>%
      add_lines(
        data = base_df, x = ~Year, y = ~Momentum,
        name = "Base scenario",
        line = list(color = "#9DBAD5", dash = "dash", width = 3)
      ) %>%
      add_lines(
        data = accel_df, x = ~Year, y = ~Momentum,
        name = "Accelerated scenario",
        line = list(color = "#6BA292", width = 4)
      ) %>%
      layout(
        xaxis = list(title = "Year"),
        yaxis = list(title = "Momentum Score (0–100)", range = c(0,100))
      )
  })
  
  # -------- Insights --------
  output$insights_text <- renderUI({
    
    current <- latest_values()
    boosted <- apply_boost_and_cascade(
      current, input$focus, input$boost,
      cor_weights, overdrive_active()
    )
    
    delta <- round(boosted - current, 1)
    
    HTML(paste0(
      "<div style='background:rgba(42,157,143,0.12);
           padding:16px;border-radius:14px;'>",
      "<b>", input$country, "</b><br><br>",
      "Accelerating <b>", input$focus, "</b> by <b>",
      input$boost, "%</b> results in:<br><br>",
      paste("• <b>", names(delta), "</b>: +", delta,
            collapse = "<br>"),
      "<br><br>",
      if (overdrive_active())
        "<b style='color:#E76F51;'>Overdrive Mode:</b> Amplified system-wide gains."
      else
        "<b>Policy insight:</b> Coordinated policy acceleration creates cross-sector spillover benefits.",
      "</div>"
    ))
  })
}

# ---------------------------------------------------------
# RUN APP
# ---------------------------------------------------------
shinyApp(ui, server)
