visualize_parent_nebula <-
  function(
           graph = .MCn.parent_graph,
           write_output = T,
           output = paste0(.MCn.output, "/", .MCn.results),
           layout = "mds",
           nodes_color = c("hierarchy" = 4), ## default, use superclass as color.
           width = 15,
           height = 12,
           return_plot = F,
           ...
           ){
    cat("[INFO] MCnebula run: visualize_parent_nebula\n")
    ## get nodes_color data
    metadata = .MCn.class_tree_data
    assign("envir_meta", environment(), envir = parent.env(environment()))
    cat("# Visualize_parent_nebula |", date(), "| USE Method: method_summarize_nebula_index.\n")
    class <- pbapply::pblapply(.MCn.ppcp_dataset, method_summarize_nebula_class, 
                               class_data_type = "classes_tree_data",
                               max_number = 1,
                               hierarchy_priority = nodes_color[["hierarchy"]] )
    class <- data.table::rbindlist(class, idcol = T) %>%
      dplyr::select(.id, name) %>%
      dplyr::rename(vis_class = name)
    ## reformat graph, add with class
    graph <- tidygraph::as_tbl_graph(graph)
    nodes <- graph %>%
      tidygraph::activate(nodes) %>%
      merge(class, by.x = "name" , by.y = ".id", all.x=TRUE, sort=F) %>%
      dplyr::mutate(vis_class = ifelse(is.na(vis_class) == T, "Unknown", vis_class)) %>%
      dplyr::as_tibble()
    edges <- graph %>%
      tidygraph::activate(edges) %>%
      ## rename the col of value of compare spectra
      dplyr::rename(similarity = 3) %>%
      dplyr::as_tibble()
    graph <- tidygraph::tbl_graph(nodes = nodes, edges = edges)
    ## create network layout
    layout_n <- ggraph::create_layout(graph, layout = layout, ...)
    ## palette
    palette <- .MCn.palette
    ## draw network via ggraph
    p <- base_vis_p_nebula(layout_n, palette)
    ## write_output
    if(write_output == T){
      ggplot2::ggsave(p, file = paste0(output, "/", "parent_nebula", "/", "parent_nebula.svg"),
             width = width, height = height)
    }
    cat("[INFO] MCnebula Job Done: visualize_parent_nebula\n")
    if(return_plot == T){
      return(p)
    }
  }
## base visualization method
base_vis_p_nebula <-
  function(
           nebula,
           palette = .MCn.palette,
           ...
           ){
    p <- ggraph::ggraph(nebula) + 
      ggraph::geom_edge_fan(aes(edge_width = similarity), color = "lightblue", show.legend = F) + 
      ggraph::geom_node_point(
                      aes(
                          size = ifelse(is.na(tanimotoSimilarity) == F, tanimotoSimilarity, 0.2),
                          fill = stringr::str_wrap(vis_class, width = 25)
                          ),
                      shape = 21
                      ) + 
      ggplot2::scale_fill_manual(values = palette) +
      ggraph::scale_edge_width(range = c(0.1, 0.7)) + 
      ggplot2::guides(fill = guide_legend(override.aes = list(size = 5))) +
      ggplot2::labs(fill="Class", size="Tanimoto similarity") +
      ggplot2::theme_grey() +
      ggplot2::theme(
            text = element_text(family = "Times"),
            axis.ticks = element_blank(),
            axis.text = element_blank(),
            axis.title = element_blank(),
            panel.background = element_rect(fill = "white"),
            legend.key.width = unit(1, "cm"),
            legend.key.height = unit(1.8, "cm"),
            legend.title = element_text(size = 20, face = "bold"),
            legend.text = element_text(size = 20),
            legend.background = element_rect(fill = "transparent"),
            panel.grid = element_blank(),
            strip.text = element_text(size = 20, face = "bold")
      )
    return(p)
  }
