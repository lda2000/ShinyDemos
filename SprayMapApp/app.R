library(shiny)
library(leaflet)
library(htmlwidgets)

class_cols <- c(A = "blue", B = "green", C = "red", D = "orange")
init_lat <- 45.4642; init_lon <- 9.19; init_zoom <- 12

ui <- fluidPage(
  tags$h3("Freehand Drawing (Shift + Click) with Spray Effect on Leaflet"),
  
  fluidRow(
    column(3,
           radioButtons("class", "Class",
                        choices = names(class_cols), selected = "A")
    ),
    column(3,
           sliderInput("spray_radius", "Spray radius (m)",
                       min = 0, max = 200, value = 30, step = 1)
    ),
    column(3,
           sliderInput("spray_intensity", "Spray intensity (points per step)",
                       min = 1, max = 5, value = 1, step = 1)
    ),
    column(3,
           div(style="padding-top:25px;",
               actionButton("clear", "Clear Points"),
               tags$span("  "),
               downloadButton("downloadData", "Download CSV")
           )
    )
  ),
  
  # Point counters per class + total
  fluidRow(
    column(12, align = "right",
           uiOutput("classCounters"),
           tags$small("Hold Shift to draw points; release to return to pan/zoom")
    )
  ),
  
  tags$style(HTML("
    #map.drawing { cursor: crosshair; }
    .badge {
      display:inline-block; padding:4px 8px; border-radius:12px; color:#fff; margin-left:6px;
      font-size: 0.9em; font-weight: 600;
    }
    .badge-A { background: blue; }
    .badge-B { background: green; }
    .badge-C { background: red; }
    .badge-D { background: orange; }
    .badge-TOTAL { background: #444; }
    .credits { font-size: 0.8em; margin-top: 10px; text-align: center; }
  ")),
  
  leafletOutput("map", height = 520),
  
  # Footer with credits
  div(class = "credits",
      "Author: ",
      tags$a(href = "https://www.linkedin.com/in/lucadellanna/", "Luca Dell'Anna", target = "_blank"),
      " | Inspired by ",
      tags$a(href = "https://www.linkedin.com/in/joachim-schork", "Joachim Schork", target = "_blank")
  )
)

server <- function(input, output, session) {
  values <- reactiveVal(data.frame(
    point_id = integer(),
    class_id = integer(),
    lon = numeric(),
    lat = numeric(),
    class = character(),
    stringsAsFactors = FALSE
  ))
  
  jitter_in_meters <- function(lat0, lon0, radius_m, n) {
    if (radius_m <= 0 || n <= 0) {
      return(data.frame(lat = rep(lat0, n), lon = rep(lon0, n)))
    }
    r <- radius_m * sqrt(runif(n))
    theta <- runif(n, 0, 2*pi)
    deg_per_m_lat <- 1 / 111320
    deg_per_m_lon <- 1 / (111320 * cos(lat0 * pi / 180))
    lat <- lat0 + (r * sin(theta)) * deg_per_m_lat
    lon <- lon0 + (r * cos(theta)) * deg_per_m_lon
    data.frame(lat = lat, lon = lon)
  }
  
  output$map <- renderLeaflet({
    m <- leaflet(options = leafletOptions(
      minZoom = 2,
      dragging = TRUE,
      boxZoom = TRUE,
      doubleClickZoom = FALSE
    )) %>%
      addProviderTiles(providers$CartoDB.Positron, group = "OSM (Light)") %>%
      addTiles(group = "OSM (Standard)") %>%
      addLayersControl(baseGroups = c("OSM (Light)", "OSM (Standard)"),
                       options = layersControlOptions(collapsed = TRUE)) %>%
      addLegend(position = "bottomright", colors = unname(class_cols),
                labels = names(class_cols), title = "Class") %>%
      setView(lng = init_lon, lat = init_lat, zoom = init_zoom)
    
    onRender(m, JS(
      "function(el, x){
         var map = this;
         var isDown = false;
         var lastSent = 0, minInterval = 160;
         
         function sendPoint(e){
           if(!isDown) return;
           var now = performance.now();
           if(now - lastSent < minInterval) return;
           lastSent = now;
           var ll = e.latlng || map.mouseEventToLatLng(e.originalEvent || e);
           if(!ll) return;
           var cls = $('input[name=\"class\"]:checked').val() || 'A';
           Shiny.setInputValue(el.id + '_freehand_point',
             { lon: ll.lng, lat: ll.lat, cls: cls, nonce: Math.random() },
             { priority: 'event' }
           );
         }
         
         map.on('mousedown', function(e){
           var oe = e.originalEvent;
           if(!oe || oe.button !== 0 || !oe.shiftKey) return;
           if(oe.preventDefault) oe.preventDefault();
           if(oe.stopPropagation) oe.stopPropagation();
           isDown = true;
           map.dragging.disable();
           if(map.boxZoom && map.boxZoom.disable) map.boxZoom.disable();
           $(el).addClass('drawing');
           sendPoint(e);
         });
         
         map.on('mousemove', sendPoint);
         
         function stop(){
           if(!isDown) return;
           isDown = false;
           map.dragging.enable();
           if(map.boxZoom && map.boxZoom.enable) map.boxZoom.enable();
           $(el).removeClass('drawing');
         }
         map.on('mouseup', stop);
         map.on('mouseout', function(ev){
           if(!ev.originalEvent || !(ev.originalEvent.buttons & 1)) stop();
         });
         window.addEventListener('blur', stop);
       }"
    ))
  })
  
  observeEvent(input$map_freehand_point, {
    p <- input$map_freehand_point
    cls <- as.character(p$cls)
    df  <- values()
    
    radius_m <- req(input$spray_radius)
    n_pts    <- req(input$spray_intensity)
    
    jittered <- jitter_in_meters(lat0 = p$lat, lon0 = p$lon, radius_m = radius_m, n = n_pts)
    
    out_list <- vector("list", n_pts)
    for (i in seq_len(n_pts)) {
      point_id <- nrow(df) + 1L
      class_id <- sum(df$class == cls) + 1L
      
      new <- data.frame(
        point_id = point_id,
        class_id = class_id,
        lon = jittered$lon[i],
        lat = jittered$lat[i],
        class = cls,
        stringsAsFactors = FALSE
      )
      df <- rbind(df, new)
      out_list[[i]] <- new
    }
    new_points <- do.call(rbind, out_list)
    values(df)
    
    col <- unname(class_cols[cls]); if (is.na(col)) col <- "black"
    
    leafletProxy("map") %>%
      addCircleMarkers(lng = new_points$lon, lat = new_points$lat,
                       radius = 5, stroke = TRUE, weight = 1, opacity = 1,
                       color = col, fillColor = col, fillOpacity = 0.9,
                       popup = paste0(
                         "<b>point_id:</b> ", new_points$point_id,
                         "<br><b>class_id:</b> ", new_points$class_id,
                         "<br><b>class:</b> ", new_points$class,
                         "<br><b>lat, lon:</b> ",
                         sprintf('%.6f, %.6f', new_points$lat, new_points$lon)
                       ))
  })
  
  observeEvent(input$clear, {
    values(data.frame(
      point_id = integer(),
      class_id = integer(),
      lon = numeric(),
      lat = numeric(),
      class = character(),
      stringsAsFactors = FALSE
    ))
    leafletProxy("map") %>% clearMarkers()
  })
  
  output$classCounters <- renderUI({
    df <- values()
    counts <- table(factor(df$class, levels = names(class_cols)))
    total  <- nrow(df)
    tags$div(
      class = "class-counters",
      tags$span(class="badge badge-TOTAL", paste0("TOTAL: ", total)),
      lapply(names(class_cols), function(k) {
        tags$span(class = paste0("badge badge-", k), paste0(k, ": ", counts[[k]] %||% 0))
      })
    )
  })
  
  output$downloadData <- downloadHandler(
    filename = function() paste0("drawn_points-", Sys.Date(), ".csv"),
    content  = function(file) write.csv(values(), file, row.names = FALSE)
  )
}

`%||%` <- function(a,b) if (is.null(a)) b else a

shinyApp(ui, server)
