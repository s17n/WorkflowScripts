FasdUAS 1.101.10   ��   ��    k             j     �� �� 0 plogfile pLogFile  m        � 	 	 F ~ / P r o j e c t s / W o r k f l o w S c r i p t s / l o g s . t x t   
  
 j    �� �� 0 pscriptname pScriptName  m       �   < C o p y   F i l e p a t h   a s   M a r k d o w n   L i n k      l     ��������  ��  ��        i    	    I      �� ���� $0 hazelprocessfile hazelProcessFile      o      ���� 0 thefile theFile   ��  o      ���� "0 inputattributes inputAttributes��  ��    k     E       l     ��������  ��  ��        l     ��  ��    7 1 'theFile' is an alias to the file that matched.	     �     b   ' t h e F i l e '   i s   a n   a l i a s   t o   t h e   f i l e   t h a t   m a t c h e d . 	   ! " ! l     �� # $��   # j d 'inputAttributes' is an AppleScript list of the values of any attributes you told Hazel to pass in.    $ � % % �   ' i n p u t A t t r i b u t e s '   i s   a n   A p p l e S c r i p t   l i s t   o f   t h e   v a l u e s   o f   a n y   a t t r i b u t e s   y o u   t o l d   H a z e l   t o   p a s s   i n . "  & ' & l     �� ( )��   ( p j Be sure to return true or false (or optionally a record) to indicate whether the file passes this script.    ) � * * �   B e   s u r e   t o   r e t u r n   t r u e   o r   f a l s e   ( o r   o p t i o n a l l y   a   r e c o r d )   t o   i n d i c a t e   w h e t h e r   t h e   f i l e   p a s s e s   t h i s   s c r i p t . '  + , + l     ��������  ��  ��   ,  - . - n     / 0 / I    �� 1���� 0 writelog writeLog 1  2�� 2 b     3 4 3 m     5 5 � 6 6  t h e F i l e :   4 o    ���� 0 thefile theFile��  ��   0  f      .  7 8 7 l  	 	��������  ��  ��   8  9 : 9 r   	  ; < ; n   	  = > = 1   
 ��
�� 
psxp > o   	 
���� 0 thefile theFile < o      ���� 0 	posixfile 	posixFile :  ? @ ? r     A B A n    C D C I    �� E���� 0 	urlencode 	urlEncode E  F�� F o    ���� 0 	posixfile 	posixFile��  ��   D  f     B o      ���� *0 posixfileurlencoded posixFileUrlEncoded @  G H G l   ��������  ��  ��   H  I J I l    K L M K r     N O N m     P P � Q Q  S c r e e n s h o t O o      ���� 	0 title   L ) # in Hazel only used for Screenshots    M � R R F   i n   H a z e l   o n l y   u s e d   f o r   S c r e e n s h o t s J  S T S r    " U V U n      W X W 4     �� Y
�� 
cobj Y m    ����  X o    ���� "0 inputattributes inputAttributes V o      ���� 0 subtitle   T  Z [ Z l  # #��������  ��  ��   [  \ ] \ r   # - ^ _ ^ I   # +�� `���� 0 create_markdown_link   `  a b a o   $ %���� 	0 title   b  c d c o   % &���� 0 subtitle   d  e�� e o   & '���� 0 	posixfile 	posixFile��  ��   _ o      ���� 0 mdlink mdLink ]  f g f n  . 6 h i h I   / 6�� j���� 0 writelog writeLog j  k�� k b   / 2 l m l m   / 0 n n � o o  m d L i n k :   m o   0 1���� 0 mdlink mdLink��  ��   i  f   . / g  p q p I  7 C�� r��
�� .JonspClpnull���     **** r K   7 ? s s �� t u
�� 
ctxt t l  8 ; v���� v c   8 ; w x w o   8 9���� 0 mdlink mdLink x m   9 :��
�� 
TEXT��  ��   u �� y��
�� 
utxt y o   < =���� 0 mdlink mdLink��  ��   q  z�� z l  D D��������  ��  ��  ��     { | { l     ��������  ��  ��   |  } ~ } i   
   �  I      �� ����� 0 create_markdown_link   �  � � � o      ���� 0 thetitle theTitle �  � � � o      ���� 0 thesubtitle theSubtitle �  ��� � o      ���� 0 thelink theLink��  ��   � k      � �  � � � r      � � � b      � � � b      � � � b     	 � � � b      � � � b      � � � b      � � � m      � � � � �  [ � o    ���� 0 thetitle theTitle � m     � � � � �    -   � o    ���� 0 thesubtitle theSubtitle � m     � � � � �  ] ( f i l e : � o   	 
���� 0 thelink theLink � m     � � � � �  ) � o      ���� 0 mdlink mdLink �  ��� � L     � � o    ���� 0 mdlink mdLink��   ~  � � � l     ��������  ��  ��   �  � � � i     � � � I      �� ����� 0 	urlencode 	urlEncode �  ��� � o      ���� 0 str  ��  ��   � k      � �  � � � q       � � ������ 0 str  ��   �  ��� � Q      � � � � L     � � l    ����� � I   �� ���
�� .sysoexecTEXT���     TEXT � b    
 � � � b     � � � m     � � � � �  / b i n / e c h o   � n     � � � 1    ��
�� 
strq � o    ���� 0 str   � l 	  	 ����� � m    	 � � � � � b   |   p e r l   - M U R I : : E s c a p e   - l n e   ' p r i n t   u r i _ e s c a p e ( $ _ ) '��  ��  ��  ��  ��   � R      �� � �
�� .ascrerr ****      � **** � o      ���� 0 emsg eMsg � �� ���
�� 
errn � o      ���� 0 enum eNum��   � R    �� � �
�� .ascrerr ****      � **** � b     � � � m     � � � � � " C a n ' t   u r l E n c o d e :   � o    ���� 0 emsg eMsg � �� ���
�� 
errn � o    ���� 0 enum eNum��  ��   �  � � � l     ��������  ��  ��   �  � � � i     � � � I      �� ����� 0 writelog writeLog �  ��� � o      ���� 0 
themessage 
theMessage��  ��   � k     # � �  � � � r      � � � I    �� ���
�� .sysoexecTEXT���     TEXT � m      � � � � � 2 d a t e   " + % Y - % m - % d   % H : % M : % S "��   � o      ���� 0 	timestamp   �  ��� � I   #�� ���
�� .sysoexecTEXT���     TEXT � b     � � � b     � � � b     � � � b     � � � b     � � � b     � � � b     � � � m    	 � � � � �  e c h o   " � o   	 
���� 0 	timestamp   � m     � � � � �  :   � o    �� 0 pscriptname pScriptName � m     � � � � �  :   � o    �~�~ 0 
themessage 
theMessage � m     � � � � � 
 "   > >   � o    �}�} 0 plogfile pLogFile��  ��   �  � � � l     �|�{�z�|  �{  �z   �  ��y � i     � � � I     �x ��w
�x .aevtoappnull  �   � **** � J      �v�v  �w   � k      � �  � � � r     
 � � � n     � � � I    �u ��t�u 0 create_markdown_link   �    m     � 
 T i t e l  m     �  U n t e r t i t e l �s m    		 �

  t h e - a c t u a l - l i n k�s  �t   �  f      � o      �r�r 0 mdlink mdLink � �q n    I    �p�o�p 0 writelog writeLog �n o    �m�m 0 mdlink mdLink�n  �o    f    �q  �y       	�l  �l   �k�j�i�h�g�f�e�k 0 plogfile pLogFile�j 0 pscriptname pScriptName�i $0 hazelprocessfile hazelProcessFile�h 0 create_markdown_link  �g 0 	urlencode 	urlEncode�f 0 writelog writeLog
�e .aevtoappnull  �   � **** �d �c�b�a�d $0 hazelprocessfile hazelProcessFile�c �`�`   �_�^�_ 0 thefile theFile�^ "0 inputattributes inputAttributes�b   �]�\�[�Z�Y�X�W�] 0 thefile theFile�\ "0 inputattributes inputAttributes�[ 0 	posixfile 	posixFile�Z *0 posixfileurlencoded posixFileUrlEncoded�Y 	0 title  �X 0 subtitle  �W 0 mdlink mdLink  5�V�U�T P�S�R n�Q�P�O�N�M�V 0 writelog writeLog
�U 
psxp�T 0 	urlencode 	urlEncode
�S 
cobj�R 0 create_markdown_link  
�Q 
ctxt
�P 
TEXT
�O 
utxt�N 
�M .JonspClpnull���     ****�a F)�%k+ O��,E�O)�k+ E�O�E�O��k/E�O*���m+ E�O)�%k+ O��&��j OP �L ��K�J�I�L 0 create_markdown_link  �K �H�H   �G�F�E�G 0 thetitle theTitle�F 0 thesubtitle theSubtitle�E 0 thelink theLink�J   �D�C�B�A�D 0 thetitle theTitle�C 0 thesubtitle theSubtitle�B 0 thelink theLink�A 0 mdlink mdLink  � � � ��I �%�%�%�%�%�%E�O� �@ ��?�>�=�@ 0 	urlencode 	urlEncode�? �<�<   �;�; 0 str  �>   �:�9�8�: 0 str  �9 0 emsg eMsg�8 0 enum eNum  ��7 ��6�5�4 �
�7 
strq
�6 .sysoexecTEXT���     TEXT�5 0 emsg eMsg �3�2�1
�3 
errn�2 0 enum eNum�1  
�4 
errn�=   ��,%�%j W X  )�l�% �0 ��/�. !�-�0 0 writelog writeLog�/ �,"�, "  �+�+ 0 
themessage 
theMessage�.    �*�)�* 0 
themessage 
theMessage�) 0 	timestamp  !  ��( � � � �
�( .sysoexecTEXT���     TEXT�- $�j E�O�%�%b  %�%�%�%b   %j  �' ��&�%#$�$
�' .aevtoappnull  �   � ****�&  �%  #  $ 	�#�"�!�# 0 create_markdown_link  �" 0 mdlink mdLink�! 0 writelog writeLog�$ )���m+ E�O)�k+ ascr  ��ޭ