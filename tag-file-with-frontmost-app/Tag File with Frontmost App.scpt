FasdUAS 1.101.10   ��   ��    k             j     �� �� 0 plogfile pLogFile  m        � 	 	 F ~ / P r o j e c t s / W o r k f l o w S c r i p t s / l o g s . t x t   
  
 j    �� �� 0 pscriptname pScriptName  m       �   6 T a g   F i l e   w i t h   F r o n t m o s t   A p p      l     ��������  ��  ��        i    	    I      �� ���� $0 hazelprocessfile hazelProcessFile      o      ���� 0 thefile theFile   ��  o      ���� "0 inputattributes inputAttributes��  ��    k     _       l     ��������  ��  ��        l     ��  ��    7 1 'theFile' is an alias to the file that matched.	     �     b   ' t h e F i l e '   i s   a n   a l i a s   t o   t h e   f i l e   t h a t   m a t c h e d . 	   ! " ! l     �� # $��   # j d 'inputAttributes' is an AppleScript list of the values of any attributes you told Hazel to pass in.    $ � % % �   ' i n p u t A t t r i b u t e s '   i s   a n   A p p l e S c r i p t   l i s t   o f   t h e   v a l u e s   o f   a n y   a t t r i b u t e s   y o u   t o l d   H a z e l   t o   p a s s   i n . "  & ' & l     �� ( )��   ( p j Be sure to return true or false (or optionally a record) to indicate whether the file passes this script.    ) � * * �   B e   s u r e   t o   r e t u r n   t r u e   o r   f a l s e   ( o r   o p t i o n a l l y   a   r e c o r d )   t o   i n d i c a t e   w h e t h e r   t h e   f i l e   p a s s e s   t h i s   s c r i p t . '  + , + l     ��������  ��  ��   ,  - . - n     / 0 / I    �� 1���� 0 writelog writeLog 1  2�� 2 b     3 4 3 m     5 5 � 6 6  t h e F i l e :   4 o    ���� 0 thefile theFile��  ��   0  f      .  7 8 7 l  	 	��������  ��  ��   8  9 : 9 r   	  ; < ; n   	  = > = 1   
 ��
�� 
psxp > o   	 
���� 0 thefile theFile < o      ���� 0 	posixfile 	posixFile :  ? @ ? r     A B A l    C���� C 5    �� D��
�� 
capp D l    E���� E l    F���� F I   �� G��
�� .earsffdralis        afdr G l    H���� H m    ��
�� appfegfp��  ��  ��  ��  ��  ��  ��  
�� kfrmname��  ��   B o      ���� 0 frontmostapp frontmostApp @  I J I I   ,�� K��
�� .sysoexecTEXT���     TEXT K b    ( L M L b    & N O N b    $ P Q P b    " R S R b      T U T b     V W V m     X X � Y Y " x a t t r   - w   s 1 7 n . a p p W m     Z Z � [ [    " U o    ���� 0 frontmostapp frontmostApp S m     ! \ \ � ] ]  " Q m   " # ^ ^ � _ _    " O o   $ %���� 0 	posixfile 	posixFile M m   & ' ` ` � a a  "��   J  b c b l  - -��������  ��  ��   c  d e d l  - -�� f g��   f "  replace spaces with dashes	    g � h h 8   r e p l a c e   s p a c e s   w i t h   d a s h e s 	 e  i j i r   - 5 k l k n  - 3 m n m I   . 3�� o���� 0 replace_spaces   o  p�� p o   . /���� 0 frontmostapp frontmostApp��  ��   n  f   - . l o      ���� (0 frontmostappdashed frontmostAppDashed j  q r q l  6 6��������  ��  ��   r  s t s n  6 B u v u I   7 B�� w���� 0 writelog writeLog w  x�� x b   7 > y z y b   7 < { | { b   7 : } ~ } m   7 8   � � �  f r o n t m o s t A p p :   ~ o   8 9���� 0 frontmostapp frontmostApp | m   : ; � � � � � , ,   f r o n t m o s t A p p D a s h e d :   z o   < =���� (0 frontmostappdashed frontmostAppDashed��  ��   v  f   6 7 t  � � � L   C ] � � K   C \ � � �� ����� .0 hazeloutputattributes hazelOutputAttributes � K   F Z � � �� � ��� 0 frontapp frontApp � l  I N ����� � c   I N � � � o   I J���� 0 frontmostapp frontmostApp � m   J M��
�� 
TEXT��  ��   � �� �����  0 frontappdashed frontAppDashed � l  Q V ����� � c   Q V � � � o   Q R���� (0 frontmostappdashed frontmostAppDashed � m   R U��
�� 
TEXT��  ��  ��  ��   �  ��� � l  ^ ^��������  ��  ��  ��     � � � l     ��������  ��  ��   �  � � � i   
  � � � I      �� ����� 0 replace_spaces   �  ��� � o      ���� 0 thetext theText��  ��   � k      � �  � � � l     ��������  ��  ��   �  � � � l     �� � ���   � 7 1 command: echo "text with spaces" | sed 's/ /-/g'    � � � � b   c o m m a n d :   e c h o   " t e x t   w i t h   s p a c e s "   |   s e d   ' s /   / - / g ' �  � � � l     �� � ���   �     return: text-with-spaces    � � � � 4     r e t u r n :   t e x t - w i t h - s p a c e s �  � � � r      � � � I    	�� ���
�� .sysoexecTEXT���     TEXT � b      � � � b      � � � m      � � � � �  e c h o   " � o    ���� 0 thetext theText � m     � � � � � " "   |   s e d   ' s /   / - / g '��   � o      ���� "0 thereplacedtext theReplacedText �  � � � L     � � o    ���� "0 thereplacedtext theReplacedText �  ��� � l   ��������  ��  ��  ��   �  � � � l     ��������  ��  ��   �  � � � i     � � � I      �� ����� 0 writelog writeLog �  ��� � o      ���� 0 
themessage 
theMessage��  ��   � k     # � �  � � � r      � � � I    �� ���
�� .sysoexecTEXT���     TEXT � m      � � � � � 2 d a t e   " + % Y - % m - % d   % H : % M : % S "��   � o      ���� 0 	timestamp   �  ��� � I   #�� ���
�� .sysoexecTEXT���     TEXT � b     � � � b     � � � b     � � � b     � � � b     � � � b     � � � b     � � � m    	 � � � � �  e c h o   " � o   	 
���� 0 	timestamp   � m     � � � � �  :   � o    ���� 0 pscriptname pScriptName � m     � � � � �  :   � o    ���� 0 
themessage 
theMessage � m     � � � � � 
 "   > >   � o    ���� 0 plogfile pLogFile��  ��   �  � � � l     ��������  ��  ��   �  ��� � i     � � � I     �� ���
�� .aevtoappnull  �   � **** � J      ����  ��   � k      � �  � � � r      � � � m      � � � � � $ S a m p l e   w i t h   d a s h e s � o      ���� 0 test   �  �� � r     � � � n   
 � � � I    
�~ ��}�~ 0 replace_spaces   �  ��| � o    �{�{ 0 test  �|  �}   �  f     � o      �z�z 0 replacement  �  ��       �y �   � � � ��y   � �x�w�v�u�t�s�x 0 plogfile pLogFile�w 0 pscriptname pScriptName�v $0 hazelprocessfile hazelProcessFile�u 0 replace_spaces  �t 0 writelog writeLog
�s .aevtoappnull  �   � **** � �r �q�p � ��o�r $0 hazelprocessfile hazelProcessFile�q �n ��n  �  �m�l�m 0 thefile theFile�l "0 inputattributes inputAttributes�p   � �k�j�i�h�g�k 0 thefile theFile�j "0 inputattributes inputAttributes�i 0 	posixfile 	posixFile�h 0 frontmostapp frontmostApp�g (0 frontmostappdashed frontmostAppDashed �  5�f�e�d�c�b�a X Z \ ^ `�`�_  ��^�]�\�[�Z�f 0 writelog writeLog
�e 
psxp
�d 
capp
�c appfegfp
�b .earsffdralis        afdr
�a kfrmname
�` .sysoexecTEXT���     TEXT�_ 0 replace_spaces  �^ .0 hazeloutputattributes hazelOutputAttributes�] 0 frontapp frontApp
�\ 
TEXT�[  0 frontappdashed frontAppDashed�Z �o `)�%k+ O��,E�O*��j �0E�O��%�%�%�%�%�%j O)�k+ E�O)�%�%�%k+ Oa a �a &a �a &a lOP � �Y ��X�W � ��V�Y 0 replace_spaces  �X �U ��U  �  �T�T 0 thetext theText�W   � �S�R�S 0 thetext theText�R "0 thereplacedtext theReplacedText �  � ��Q
�Q .sysoexecTEXT���     TEXT�V �%�%j E�O�OP � �P ��O�N �M�P 0 writelog writeLog�O �L�L   �K�K 0 
themessage 
theMessage�N    �J�I�J 0 
themessage 
theMessage�I 0 	timestamp    ��H � � � �
�H .sysoexecTEXT���     TEXT�M $�j E�O�%�%b  %�%�%�%b   %j  � �G ��F�E�D
�G .aevtoappnull  �   � ****�F  �E      ��C�B�A�C 0 test  �B 0 replace_spaces  �A 0 replacement  �D �E�O)�k+ E�ascr  ��ޭ