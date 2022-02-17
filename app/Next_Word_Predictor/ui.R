# ui.R
# Author: Surabh
# Date: 02/13/2022
# Description: Shiny UI

library(shiny)
library(shinythemes)
library(markdown)
library(dplyr)
library(tm)

shinyUI(
    navbarPage("Next Word Predictor",
               theme = shinytheme("cosmo"),
               tabPanel("Home",
                        fluidPage(
                            titlePanel("Home"),
                            sidebarLayout(
                                sidebarPanel(
                                    textInput("userInput",
                                              "Enter a word or phrase:",
                                              value =  "",
                                              placeholder = "Enter text here"),
                                    br(),
                                    sliderInput("numPredictions", "Number of Predictions:",
                                                value = 1.0, min = 1.0, max = 3.0, step = 1.0)
                                ),
                                mainPanel(
                                    h4("Input text"),
                                    verbatimTextOutput("userSentence"),
                                    br(),
                                    h4("Predicted words"),
                                    verbatimTextOutput("prediction1"),
                                    verbatimTextOutput("prediction2"),
                                    verbatimTextOutput("prediction3")
                                )
                            )
                        )
               ),
               tabPanel("About",
                        h3("Next Word Predictor"),
                        br(),
                        div("Next Word Predictor is an application built in Shiny that predicts the next word
                            based on text entered by a user using a text based algorithm.",
                            br(),
                            br(),
                            "When the app detects that you have finished typing one or more
                            words, the predicted word(s) will be shown. When entering text, please allow a few
                            seconds for the output to appear.",
                            br(),
                            br(),
                            "You can choose from 1 to 3 most likely next word using the slider. The top prediction will be
                            shown first followed by the second and third likely next words.",
                            br(),
                            br(),
                            "The source code for this application can be found
                            on GitHub:",
                            br(),
                            br(),
                            img(src = "github.png"),
                            a(target = "_blank", href = "http://github.com/sregmi84/Data-Science-Capstone-Project",
                              "Next Word Predictor"))
                        
               )
    )
)