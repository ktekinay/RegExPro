#tag Class
Protected Class RegExPro_MTC
	#tag Method, Flags = &h21
		Private Sub Compile()
		  declare function pcre_compile lib kPCRELib ( pattern as CString, options as Int32, ByRef error as CString, ByRef errorOffset as Int32, useCharTables as ptr) As Ptr
		  
		  RePtr = pcre_compile( SearchPattern, 0, ErrorString, ErrorOffset, nil )
		  MaybeRaiseException
		  
		  StudyDataPtr = nil
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Destructor()
		  Reset
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Exec()
		  if not IsCompiled then
		    Compile
		  elseif not IsStudied then // Will study on second pass
		    Study
		  end if
		  
		  if IsEndOfFile then
		    SubExpressionCount = 0
		    return
		  end if
		  
		  declare function pcre_exec lib kPCRELib ( _
		  re as ptr, _
		  extraData as ptr, _
		  subject as CString, _
		  subjectLen as Int32, _
		  offset as Int32, _
		  options as Int32, _
		  ovector as ptr, _
		  vectorElementCount as Int32 _
		  ) as Int32
		  
		  var elementCount as Int32 = AllowedSubgroups * 3
		  var mbSize as integer = elementCount * 4
		  if VectorMB is nil or VectorMB.Size <> mbSize then
		    VectorMB = new MemoryBlock( mbSize)
		  end if
		  
		  var vectorPtr as ptr = VectorMB
		  
		  var errOrCount as integer = pcre_exec( RePtr, StudyDataPtr, SubjectCString, SubjectLenB, NextOffset, 0, vectorPtr, elementCount )
		  MaybeRaiseException
		  
		  if errOrCount = kPCREErrorNoMatch then
		    //
		    // We're done
		    //
		    SubExpressionCount = 0
		    
		  elseif SubExpressionCount < 0 then
		    //
		    // Some error wasn't caught
		    //
		    ErrorString = "PCRE Error " + errOrCount.ToString
		    MaybeRaiseException
		    
		  else
		    SubExpressionCount = errOrCount
		    
		    //
		    // Set up the NextOffset
		    //
		    var thisOffset as Int32 = NextOffset
		    NextOffset = vectorPtr.UInt32( 4 )
		    if NextOffset = thisOffset then
		      NextOffset = NextOffset + 1
		    end if
		    
		  end if
		  
		  return
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub MaybeRaiseException()
		  var errorString as string = self.ErrorString
		  
		  if errorString <> "" then
		    var err as new RegExSearchPatternException
		    err.Message = if( errorString = "", "An error has occurred", errorString ) + "; " + ErrorOffset.ToString
		    ResetError
		    Reset
		    VectorMB = nil
		    
		    raise err
		  end if
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Reset()
		  if StudyDataPtr <> nil then
		    declare sub pcre_free_study lib kPCRELib ( extraData as ptr )
		    pcre_free_study( StudyDataPtr )
		    StudyDataPtr = nil
		  end if
		  
		  if RePtr <> nil then
		    declare sub pcre_free lib kPCRELib ( re as ptr )
		    pcre_free( RePtr )
		    RePtr = nil
		  end if
		  
		  SubExpressionCount = 0
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub ResetError()
		  ErrorString = ""
		  ErrorOffset = 0
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Search()
		  //
		  // Continues the search from the current position
		  //
		  Exec
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Search(targetString As String, startingBytePos As Integer = 0)
		  if targetString.Encoding isa object and targetString.Encoding <> Encodings.UTF8 then
		    targetString = targetString.ConvertEncoding( Encodings.UTF8 )
		  end if
		  
		  Subject = targetString
		  SubjectCString = Subject
		  SubjectLenB = targetString.Bytes
		  NextOffset = startingBytePos
		  
		  Exec
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h21
		Private Sub Study()
		  declare function pcre_study lib kPCRELib ( re as ptr, options as Int32, ByRef error as CString ) as ptr
		  
		  StudyDataPtr = pcre_study( RePtr, 0, ErrorString )
		  MaybeRaiseException
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SubExpressionString(index As Integer) As String
		  if VectorMB is nil or index < 0 or index >= SubExpressionCount then
		    raise new OutOfBoundsException
		  end if
		  
		  index = index * 2 // Because we use every other one
		  
		  var firstValBytePos as integer = index * 4
		  var secondValBytePos as integer = ( index + 1 ) * 4
		  
		  var p as ptr = VectorMB
		  
		  var startingPosB as integer = p.Int32( firstValBytePos )
		  var endingPosB as integer = p.Int32( secondValBytePos )
		  var length as integer = endingPosB - startingPosB
		  if length = 0 then
		    return ""
		  else
		    return Subject.MiddleBytes( startingPosB, length )
		  end if
		End Function
	#tag EndMethod


	#tag Property, Flags = &h21
		Private AllowedSubgroups As Integer = 100
	#tag EndProperty

	#tag Property, Flags = &h21
		Private ErrorOffset As Int32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private ErrorString As CString
	#tag EndProperty

	#tag ComputedProperty, Flags = &h21
		#tag Getter
			Get
			  return RePtr <> nil
			End Get
		#tag EndGetter
		Private IsCompiled As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  return NextOffset >= SubjectLenB
			  
			End Get
		#tag EndGetter
		IsEndOfFile As Boolean
	#tag EndComputedProperty

	#tag ComputedProperty, Flags = &h21
		#tag Getter
			Get
			  return StudyDataPtr <> nil
			End Get
		#tag EndGetter
		Private IsStudied As Boolean
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private mOptions As RegExOptions
	#tag EndProperty

	#tag Property, Flags = &h21
		Private mSearchPattern As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private NextOffset As Int32
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  if mOptions is nil then
			    mOptions = new RegExOptions
			  end if
			  
			  return mOptions
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  mOptions = value
			End Set
		#tag EndSetter
		Options As RegExOptions
	#tag EndComputedProperty

	#tag Property, Flags = &h0
		ReplacementPattern As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private RePtr As Ptr
	#tag EndProperty

	#tag ComputedProperty, Flags = &h0
		#tag Getter
			Get
			  Return mSearchPattern
			End Get
		#tag EndGetter
		#tag Setter
			Set
			  Reset
			  
			  mSearchPattern = value
			  if mSearchPattern.Encoding isa object and mSearchPattern.Encoding <> Encodings.UTF8 then
			    mSearchPattern = mSearchPattern.ConvertEncoding( Encodings.UTF8 )
			  end if
			  
			End Set
		#tag EndSetter
		SearchPattern As String
	#tag EndComputedProperty

	#tag Property, Flags = &h21
		Private StudyDataPtr As Ptr
	#tag EndProperty

	#tag Property, Flags = &h0
		SubExpressionCount As Integer
	#tag EndProperty

	#tag Property, Flags = &h21
		Private Subject As String
	#tag EndProperty

	#tag Property, Flags = &h21
		Private SubjectCString As CString
	#tag EndProperty

	#tag Property, Flags = &h21
		Private SubjectLenB As Int32
	#tag EndProperty

	#tag Property, Flags = &h21
		Private VectorMB As MemoryBlock
	#tag EndProperty


	#tag Constant, Name = kPCREErrorNoMatch, Type = Double, Dynamic = False, Default = \"-1", Scope = Private
	#tag EndConstant

	#tag Constant, Name = kPCRELib, Type = String, Dynamic = False, Default = \"", Scope = Private
		#Tag Instance, Platform = Mac OS, Language = Default, Definition  = \"@executable_path/../Frameworks/pcre_libs/libpcre.1.dylib"
	#tag EndConstant


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="ReplacementPattern"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SearchPattern"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="String"
			EditorType="MultiLineEditor"
		#tag EndViewProperty
		#tag ViewProperty
			Name="SubExpressionCount"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="IsEndOfFile"
			Visible=false
			Group="Behavior"
			InitialValue=""
			Type="Boolean"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass
