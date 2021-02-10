#tag Class
Protected Class RegExProTests
Inherits TestGroup
	#tag Method, Flags = &h0
		Sub SearchTest()
		  var rx as new RegExPro_MTC
		  rx.SearchPattern = "a(b)(c)"
		  rx.Search( "abc" )
		  Assert.AreEqual 3, rx.SubExpressionCount
		  Assert.AreSame "abc", rx.SubExpressionString( 0 )
		  Assert.AreSame "b", rx.SubExpressionString( 1 )
		  Assert.AreSame "c", rx.SubExpressionString( 2 )
		  Assert.IsTrue rx.IsEndOfFile
		  
		  rx.Search
		  Assert.AreEqual 0, rx.SubExpressionCount
		  
		End Sub
	#tag EndMethod


End Class
#tag EndClass
