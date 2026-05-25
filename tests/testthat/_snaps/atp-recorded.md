# atp_get_episodes schema snapshot is stable

    Code
      glimpse_schema(out)
    Output
      # A tibble: 11 x 2
         col      class    
         <chr>    <chr>    
       1 number   character
       2 title    character
       3 duration hms      
       4 date     Date     
       5 year     numeric  
       6 month    ordered  
       7 weekday  ordered  
       8 links    list     
       9 n_links  integer  
      10 network  character
      11 show     character

