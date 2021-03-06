library(tm)
library(data.table)
library(shiny)
library(ggplot2)

#read in data from .csv file (downloaded from kaggle.com)
usPresDebate <- read.csv("debate.csv")
#subset to exclude moderators, and focus only the candidates
candidatesOnly <- subset(usPresDebate, usPresDebate$Speaker=="Trump" | usPresDebate$Speaker=="Clinton")

#make sure variables are in correct format
candidatesOnly$Speaker <- factor(candidatesOnly$Speaker)
candidatesOnly$Text <- iconv(candidatesOnly$Text,"WINDOWS-1252","UTF-8")

#create seperate dataframes for each candidate (just neater)
trumpOnly <- candidatesOnly[candidatesOnly$Speaker=="Trump",]
clintonOnly <- candidatesOnly[candidatesOnly$Speaker=="Clinton",]

shinyServer(function(input, output){
 
  observeEvent(input$update, {
    
    output$printText <- reactive({
      #get input word from user and count number of times each candidate says it
      folksC <- length(grep(tolower(input$word), tolower(clintonOnly$Text)))
      folksT <- length(grep(tolower(input$word), tolower(trumpOnly$Text)))
      
      #use that to assign correct name to who said it more/ less
      whoMore <- ifelse(folksC < folksT, "Trump", "Clinton")
      moretimes <- ifelse(folksC < folksT, folksT, folksC)
      whoLess <- ifelse(folksC > folksT, "Trump", "Clinton")
      lesstimes <- ifelse(folksC > folksT, folksT, folksC)
      #paste together correct output text
      textDiff <- paste0("The word or phrase you enfered was ", 
                         tolower(input$word), 
                         ". This was used most frequently by ",  
                         whoMore,
                         ", who mentioned it ",
                         moretimes, " times",
                         ". (", 
                         whoLess, " mentioned this word only ", 
                         lesstimes, " times).")
                         #also create text to output in case there is no difference between them 
                         textSame <- paste0("The word or phrase you enfered was ", 
                                            tolower(input$word), ". ",
                                            "Both candidates mentioned this word ", 
                                            moretimes, " times.")
                         
                         #assign final output text               
                         printText <- ifelse(folksT==folksC, textSame, textDiff)
                         printText
      
    })
    output$trumpGraphText <- reactive({
      paste0("Trump uses the following words associated with ", tolower(input$word), ": ")
    })
    
    output$clintonGraphText <- reactive({
      paste0("Clinton uses the following words associated with ", tolower(input$word), ": ")
    })
    
    #create corpus for each candidate to see associated words. 
    clintonCorpus <- Corpus(VectorSource(clintonOnly$Text))
    tdmClinton <- TermDocumentMatrix(clintonCorpus,
                              control = list(removePunctuation = TRUE,
                                             stopwords = TRUE))
    
    
    trumpCorpus <- Corpus(VectorSource(trumpOnly$Text))
    tdmTrump <- TermDocumentMatrix(trumpCorpus,
                              control = list(removePunctuation = TRUE,
                                             stopwords = TRUE))
    
    clintonAssoc <- findAssocs(tdmClinton, tolower(input$word), 0.6)
    clintonAssoc <- as.data.frame(clintonAssoc)
    clintonAssoc <- setDT(clintonAssoc, keep.rownames = TRUE)[]
    names(clintonAssoc)[2] <- "corr"
    
    trumpAssoc <- findAssocs(tdmTrump, tolower(input$word), 0.6)
    trumpAssoc <- as.data.frame(trumpAssoc)
    trumpAssoc <- setDT(trumpAssoc, keep.rownames = TRUE)[]
    names(trumpAssoc)[2] <- "corr"
    
    output$clintonGraph <- renderPlot({
      
      #graph of associated words for Clinton
      ggplot(clintonAssoc, aes(x=reorder(rn, corr), y=corr)) + 
        geom_bar(stat = "identity") + 
        theme_bw() + 
        theme(text=element_text(size=18))  +
        coord_flip() +
        labs(y="Correlation of each term \n(only 0.6 and over are shown)", x="Associated word")
      
    })
    
    output$trumpGraph <- renderPlot({
      
      #graph of associated words for Clinton
      ggplot(trumpAssoc, aes(x=reorder(rn, corr), y=corr)) + 
        geom_bar(stat = "identity") + 
        theme_bw() + 
        theme(text=element_text(size=18))  +
        coord_flip() +
        labs(y="Correlation of each term \n(only 0.6 and over are shown)", x="Associated word")
      
    })
    
  })  




   

})               