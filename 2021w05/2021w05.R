## ----setup, include=FALSE-----------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, comment = "")


## -----------------------------------------------------------------------------------------------------------------------------------
library(dplyr)
library(readr)
library(ggplot2)
library(ggdark)
library(tidyr)
library(patchwork)


## -----------------------------------------------------------------------------------------------------------------------------------
plastics <-read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2021/2021-01-26/plastics.csv')


## -----------------------------------------------------------------------------------------------------------------------------------
str(plastics)
DataExplorer::plot_intro(plastics)


## -----------------------------------------------------------------------------------------------------------------------------------
plastics %>% group_by(country) %>% count()


## -----------------------------------------------------------------------------------------------------------------------------------
plastics %>% group_by(parent_company) %>% count()
plastics %>% group_by(parent_company == "Grand Total") %>% summarise(n=sum(grand_total, na.rm = T)) %>% mutate(n2 = n/sum(n)*100)


## -----------------------------------------------------------------------------------------------------------------------------------
plastics <- plastics %>% filter(parent_company != "Grand Total")


## -----------------------------------------------------------------------------------------------------------------------------------
plastics %>% group_by(num_events) %>% count()


## -----------------------------------------------------------------------------------------------------------------------------------
plastics %>% group_by(volunteers) %>% count()


## -----------------------------------------------------------------------------------------------------------------------------------
world_data <- map_data('world')


world_data %>% group_by(region) %>% count()

plastics %>% 
  group_by(region = country) %>% 
  count() %>% 
  left_join(
  world_data %>%
    group_by(region) %>%
    summarise(n2 = n()),
  copy = T
)


## -----------------------------------------------------------------------------------------------------------------------------------
world_data %>% group_by(region) %>% count()

plastics <- plastics %>% 
  mutate(
    country = case_when(
      country == "Cote D_ivoire" ~ "Ivory Coast",
      country == "ECUADOR" ~ "Ecuador",
      country == "Korea" ~ "South Korea",
      country == "Hong Kong" ~ "China",
      country == "NIGERIA" ~ "Nigeria",
      country == "Taiwan_ Republic of China (ROC)" ~ "Taiwan",
      country == "United Kingdom" ~ "UK",
      country == "United Kingdom of Great Britain & Northern Ireland" ~ "UK",
      country == "United States of America" ~ "USA",
      TRUE ~ country
    ) 
  )

(map <- world_data %>% left_join(
plastics %>% 
  filter(year == 2020) %>% 
  group_by(region = country) %>% 
  summarise(Plastics = sum(grand_total, na.rm = T))# %>% left_join(world_data %>% group_by(region) %>% count())
  ) %>% ggplot(aes(long, lat)) +
  geom_polygon(aes(group = group, fill = Plastics))+
  dark_theme_classic()+
    labs(
      title = "by country"
    )+
    xlab(NULL)+
    ylab(NULL))


## -----------------------------------------------------------------------------------------------------------------------------------
(c_plot <- plastics %>% 
  filter(year == 2020) %>% 
  group_by(parent_company) %>% 
  summarise(
    plastics = sum(grand_total, na.rm = T)
  ) %>% 
  mutate(
    parent_company = case_when(
      parent_company %in% c("null", "NULL") ~ "Unbranded",
      plastics < 1000 ~ "Others",
      TRUE ~ parent_company
    )
  ) %>% 
  group_by(parent_company) %>% 
  summarise(
    plastics = sum(plastics)
  ) %>% 
  mutate(
    labels = paste0(round(plastics/1000), "K")
  )%>% 
  ggplot(aes(parent_company, plastics)) +
  geom_bar(stat = 'identity')+
  geom_text(aes(label=labels))+
  coord_flip()+
  dark_theme_classic()+
   labs(
     title = "by company"
   ) +
   ylab("Plastics")+
   xlab("Parent company"))


## -----------------------------------------------------------------------------------------------------------------------------------
(t_plot <- plastics %>% 
  filter(year == 2020) %>% 
  select(4:11) %>% 
  pivot_longer(everything()) %>% 
  group_by(name) %>% 
  summarise(
    value = sum(value)
  ) %>% 
   mutate(name = case_when(
     name == "hdpe" ~ "High density polyethylene",
     name == "ldpe" ~ "Low density polyethylene",
     name == "o" ~ "Other",
     name == "pet" ~ "Polyester plastic",
     name == "pp" ~ "Polypropylene",
     name == "ps" ~ "Polystyrene",
     name == "pvc" ~ "PVC plastic",
     TRUE ~ name
   ))%>% 
  ggplot(aes(name, value))+
  geom_bar(stat = 'identity')+
   geom_text(aes(label=format(value, big.mark = ",")), vjust = -0.4) +
  scale_x_discrete(labels = function(x) stringr::str_wrap(x, width = 10))+
  dark_theme_classic()+
   labs(
     title = "by type"
   )+
   xlab("Types")+
   ylab("Plastics"))


## -----------------------------------------------------------------------------------------------------------------------------------
(ne <- plastics %>% 
  filter(year == 2020) %>% 
  summarise(sum(num_events)) %>% 
  .[[1]] %>% 
  format(big.mark = ','))

(nv <- plastics %>% 
  filter(year == 2020) %>% 
  summarise(sum(volunteers, na.rm = T)) %>% 
  .[[1]] %>% 
  format(big.mark = ','))


## -----------------------------------------------------------------------------------------------------------------------------------
patchwork <- c_plot/map/t_plot
patchwork +
  plot_annotation(
    title = "Plastic Pollution",
    subtitle = glue::glue("2020 Audit wiith {ne} events and {nv} volunteers."),
    caption = "2021-01-26 #TidyTuesday by @drdsdaniel",
    theme = dark_theme_classic()
  )+
  theme(text = element_text(size = 14))

